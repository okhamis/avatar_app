import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../debug/test_data_helper.dart';
import '../../providers/auth_provider.dart';
import '../../config/content_strings.dart';
import '../../providers/avatar_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_glass_bar.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class VoiceRecordScreen extends ConsumerStatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  ConsumerState<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends ConsumerState<VoiceRecordScreen> with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPlayingPreview = false;
  bool _isSubmitting = false;
  Timer? _playbackTimer;
  String? _recordedFilePath;
  // Debug: result of last ElevenLabs clone attempt
  String? _cloneResultVoiceId; // non-null = success, empty string = tried but failed
  String? _cloneErrorHint;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<List<int>>? _streamSub;
  StreamSubscription<void>? _playerCompletionSub;
  final List<List<int>> _pcmChunks = [];

  static const int _wavSampleRate = 44100;
  static const int _wavChannels = 1;
  static const int _wavBitsPerSample = 16;
  late final List<AnimationController> _waveCtrls;

  @override
  void initState() {
    super.initState();
    _playerCompletionSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlayingPreview = false);
    });
    _waveCtrls = List.generate(
      11,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 650 + (i * 37 % 280)),
      )..repeat(reverse: true),
    );
    // In debug mode, try to load test voice recording automatically
    if (kDebugMode) {
      _loadTestVoiceIfAvailable();
    }
  }

  Future<void> _loadTestVoiceIfAvailable() async {
    try {
      final testVoice = await TestDataHelper.loadTestVoiceRecording();
      if (testVoice != null && mounted) {
        setState(() {
          _recordedFilePath = testVoice.path;
        });
        debugPrint('[VOICE] Auto-loaded test voice from ${testVoice.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loaded test voice from Documents'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[VOICE] Error loading test voice: $e');
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _streamSub?.cancel();
    _playerCompletionSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    for (final c in _waveCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool _busy = false;

  Future<void> _toggleRecording() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('[VOICE] hasPermission=$hasPermission');
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record.')),
        );
        return;
      }

      await _player.stop();
      _playbackTimer?.cancel();
      _pcmChunks.clear();

      debugPrint('[VOICE] Starting stream recording...');
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _wavSampleRate,
          numChannels: _wavChannels,
        ),
      );

      _streamSub = stream.listen((data) {
        _pcmChunks.add(data);
      });

      debugPrint('[VOICE] Stream recording started');
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isPlayingPreview = false;
        _recordedFilePath = null;
      });
    } catch (e) {
      debugPrint('[VOICE] Start recording error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    debugPrint('[VOICE] Stopping — chunks=${_pcmChunks.length}');

    // 1. Detach stream (fire-and-forget, native cancel is broken).
    _streamSub?.cancel();
    _streamSub = null;

    // 2. Fire-and-forget native stop.
    _recorder.stop().timeout(const Duration(seconds: 1), onTimeout: () => null).catchError((_) => null);

    // 3. Build WAV from collected PCM chunks and write in one shot.
    int totalPcmBytes = 0;
    for (final chunk in _pcmChunks) {
      totalPcmBytes += chunk.length;
    }
    debugPrint('[VOICE] PCM bytes collected: $totalPcmBytes');

    String? path;
    if (totalPcmBytes > 0) {
      // Use Application Support + explicit subfolder (Documents/Caches layout varies by platform;
      // missing parents caused PathNotFoundException on some macOS sandbox builds).
      final Directory supportDir = await getApplicationSupportDirectory();
      final Directory voiceDir = Directory(
        '${supportDir.path}/voice_recordings',
      );
      await voiceDir.create(recursive: true);
      path =
          '${voiceDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      final Uint8List wavBytes = _buildWavFile(totalPcmBytes);
      final File outFile = File(path);
      try {
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(wavBytes, flush: true);
        debugPrint(
          '[VOICE] WAV written: $path (${wavBytes.length} bytes)',
        );
      } catch (e, st) {
        debugPrint('[VOICE] WAV write failed: $e\n$st');
        path = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save recording: $e')),
          );
        }
      }
    }

    _pcmChunks.clear();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null) {
        _recordedFilePath = path;
      }
    });
    debugPrint('[VOICE] Stop complete, hasFile=${path != null}');
  }

  /// Assembles a complete WAV file (header + PCM data) from collected chunks.
  Uint8List _buildWavFile(int totalPcmBytes) {
    final byteRate = _wavSampleRate * _wavChannels * _wavBitsPerSample ~/ 8;
    final blockAlign = _wavChannels * _wavBitsPerSample ~/ 8;
    final out = ByteData(44 + totalPcmBytes);

    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        out.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // WAV header (44 bytes)
    ascii(0, 'RIFF');
    out.setUint32(4, totalPcmBytes + 36, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    out.setUint32(16, 16, Endian.little);
    out.setUint16(20, 1, Endian.little);
    out.setUint16(22, _wavChannels, Endian.little);
    out.setUint32(24, _wavSampleRate, Endian.little);
    out.setUint32(28, byteRate, Endian.little);
    out.setUint16(32, blockAlign, Endian.little);
    out.setUint16(34, _wavBitsPerSample, Endian.little);
    ascii(36, 'data');
    out.setUint32(40, totalPcmBytes, Endian.little);

    // PCM data
    var offset = 44;
    for (final chunk in _pcmChunks) {
      for (final byte in chunk) {
        out.setUint8(offset++, byte);
      }
    }

    return out.buffer.asUint8List();
  }

  Future<void> _playbackPreview() async {
    if (_isRecording) {
      await _stopRecording();
    }
    if (!mounted) return;
    final filePath = _recordedFilePath;
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record your voice first, then play it back.')),
      );
      return;
    }

    final file = File(filePath);
    final exists = await file.exists();
    final bytes = exists ? await file.length() : 0;
    debugPrint('[VOICE] Playback: path=$filePath exists=$exists bytes=$bytes');
    if (!exists || bytes < 100) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording file is empty. Please re-record.')),
      );
      return;
    }

    try {
      await _player.stop();
      _playbackTimer?.cancel();
      await _player.setVolume(1.0);
      setState(() => _isPlayingPreview = true);
      debugPrint('[VOICE] Playing DeviceFileSource...');
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('[VOICE] Playback error: $e');
      if (!mounted) return;
      setState(() => _isPlayingPreview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback failed: $e')),
      );
    }
  }

  Future<void> _handleContinue() async {
    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again before continuing.')),
      );
      return;
    }

    if (_isRecording) await _stopRecording();

    setState(() {
      _isSubmitting = true;
      _cloneResultVoiceId = null;
      _cloneErrorHint = null;
    });
    final notifier = ref.read(avatarProvider.notifier);
    final authNotifier = ref.read(authProvider.notifier);

    try {
      // 1. Clone voice and await the result so we know if it succeeded.
      final samplePath = _recordedFilePath ?? '';
      debugPrint('[VOICE_RECORD][STEP1] samplePath=$samplePath');
      String clonedVoiceId = '';
      if (samplePath.isNotEmpty) {
        try {
          debugPrint('[VOICE_RECORD][STEP2] calling saveVoiceDraft...');
          clonedVoiceId = await notifier.saveVoiceDraft(
            ownerId: user.uid,
            samplePath: samplePath,
          );
          debugPrint('[VOICE_RECORD][STEP3] saveVoiceDraft returned voiceId=$clonedVoiceId');
        } catch (e) {
          debugPrint('[VOICE_RECORD][STEP3] saveVoiceDraft error: $e');
          if (mounted) {
            setState(() {
              _cloneResultVoiceId = '';
              _cloneErrorHint = e.toString();
            });
          }
        }
      } else {
        debugPrint('[VOICE_RECORD][STEP2] No recording — skipping clone');
      }

      if (mounted) {
        setState(() {
          _cloneResultVoiceId = clonedVoiceId;
          _cloneErrorHint = clonedVoiceId.isEmpty && samplePath.isNotEmpty
              ? 'Clone returned empty voice_id — check API key plan (Creator+) and audio length'
              : null;
        });
      }

      // 2. Mark training flag (after clone attempt so we have a real result).
      debugPrint('[VOICE_RECORD][STEP4] calling updateTrainingFlags...');
      await authNotifier.updateTrainingFlags(hasVoiceCloned: true);
      debugPrint('[VOICE_RECORD][STEP5] hasVoiceCloned=true set');

      // 3. In debug mode, pause briefly so the banner is visible before navigation.
      if (kDebugMode && mounted) {
        await Future.delayed(const Duration(seconds: 2));
      }

      // 4. Navigate explicitly.
      if (!mounted) return;
      context.goNamed(RouteNames.behavioralTraining);
    } catch (e) {
      debugPrint('[VOICE_RECORD] Voice setup error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice setup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _recordedFilePath != null && _recordedFilePath!.isNotEmpty;
    final hasVoiceSample = complete;
    final audioActive = _isRecording || _isPlayingPreview;
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      extendBodyBehindAppBar: true,
      appBar: PresntGlassTopBar(
        leading: IconButton(
          onPressed: () async {
            await _recorder.stop();
            await _player.stop();
            if (!mounted) return;
            // Undo the face-trained flag so the redirect returns to /face-upload.
            await ref.read(authProvider.notifier).updateTrainingFlags(hasFaceTrained: false);
          },
          icon: const Icon(Icons.keyboard_backspace_rounded, color: PresntTokens.primary),
        ),
        title: Text(
          'Presnt',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PresntTokens.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 64,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: 3 / 6,
                      backgroundColor: PresntTokens.surfaceContainerHigh,
                      color: PresntTokens.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STEP 3 OF 6',
                  style: GoogleFonts.inter(fontSize: 8, letterSpacing: 1.5, color: PresntTokens.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.goNamed(RouteNames.settings),
            icon: Icon(Icons.settings_outlined, color: PresntTokens.surfaceBright.withValues(alpha: 0.5)),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 72),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Let's capture your voice",
                    style: GoogleFonts.manrope(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.5,
                      color: PresntTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Read the sample text below clearly.',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      color: PresntTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: PresntTokens.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: PresntTokens.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        kVoiceRecordingSampleScript,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: PresntTokens.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_waveCtrls.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedBuilder(
                            animation: _waveCtrls[i],
                            builder: (context, _) {
                              final h = 8 + _waveCtrls[i].value * 26;
                              final col = i % 3 == 1 ? PresntTokens.secondary : PresntTokens.primary;
                              return Container(
                                width: 4,
                                height: audioActive ? h : 8 + (i % 4) * 2.0,
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _MicPulseButton(
                      isRecording: _isRecording,
                      onTap: () => _toggleRecording(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: hasVoiceSample ? _playbackPreview : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PresntTokens.onSurfaceVariant,
                            side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text('PLAYBACK', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            _playbackTimer?.cancel();
                            await _recorder.stop();
                            await _player.stop();
                            _streamSub?.cancel();
                            _pcmChunks.clear();
                            setState(() {
                              _isRecording = false;
                              _isPlayingPreview = false;
                              _recordedFilePath = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PresntTokens.onSurfaceVariant,
                            side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('RE-RECORD', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode && _cloneResultVoiceId != null)
            _DebugCloneBanner(
              voiceId: _cloneResultVoiceId!,
              errorHint: _cloneErrorHint,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: PresntGradientCta(
              label: _isSubmitting ? 'Cloning your voice...' : 'Clone Voice & Continue',
              onPressed: (!_isSubmitting && complete) ? _handleContinue : null,
              trailing: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(PresntTokens.onPrimaryFixed),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug-only banner shown after a clone attempt.
class _DebugCloneBanner extends StatelessWidget {
  final String voiceId;
  final String? errorHint;

  const _DebugCloneBanner({required this.voiceId, this.errorHint});

  @override
  Widget build(BuildContext context) {
    final success = voiceId.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade900.withValues(alpha: 0.85) : Colors.red.shade900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? Colors.greenAccent : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? 'ElevenLabs clone OK' : 'ElevenLabs clone FAILED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  success ? 'voice_id: $voiceId' : (errorHint ?? 'voice_id empty — check logs'),
                  style: TextStyle(
                    color: success ? Colors.greenAccent.shade100 : Colors.redAccent.shade100,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicPulseButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const _MicPulseButton({required this.isRecording, required this.onTap});

  @override
  State<_MicPulseButton> createState() => _MicPulseButtonState();
}

class _MicPulseButtonState extends State<_MicPulseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final scale = 1.0 + (widget.isRecording ? 0.06 * (0.5 + 0.5 * (1 - (_pulse.value - 0.5).abs() * 2)) : 0);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PresntTokens.primaryCtaGradient,
            boxShadow: [
              BoxShadow(
                color: PresntTokens.primary.withValues(alpha: 0.35),
                blurRadius: widget.isRecording ? 28 : 12,
                spreadRadius: widget.isRecording ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            size: 44,
            color: PresntTokens.onPrimaryFixed,
          ),
        ),
      ),
    );
  }
}
