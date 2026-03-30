import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../config/app_config.dart';
import '../../routes/route_names.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/liveavatar_service.dart';
import '../../services/elevenlabs_service.dart';
import '../../services/did_service.dart';
import '../../services/gemini_service.dart';
import '../../services/firebase_service.dart';
import '../../models/live_kit_session.dart';
import '../../widgets/live_kit_video.dart';
import '../../widgets/did_webrtc_video.dart';
import '../../providers/streaming_settings_provider.dart';
import '../../config/test_profile_config.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/avatar_preview_display.dart';
import '../../core/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveConversationScreen extends ConsumerStatefulWidget {
  const LiveConversationScreen({super.key});

  @override
  ConsumerState<LiveConversationScreen> createState() => _LiveConversationScreenState();
}

class _LiveConversationScreenState extends ConsumerState<LiveConversationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final FlutterTts _flutterTts = FlutterTts();
  final ElevenLabsService _elevenLabs = ElevenLabsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _sessionActive = true;
  Duration _elapsed = Duration.zero;
  Timer? _durationTimer;
  final LiveAvatarService _liveAvatarService = LiveAvatarService();
  final DidService _didService = DidService();
  final GeminiService _geminiService = GeminiService();
  final GlobalKey<DidWebrtcVideoState> _didVideoKey = GlobalKey<DidWebrtcVideoState>();
  final FirebaseService _firebaseService = FirebaseService();
  
  /// Active Streaming Engine (default matches [StreamingEngineNotifier]).
  StreamingEngine _activeEngine = StreamingEngine.dId;
  
  /// LiveAvatar Session
  LiveKitSession? _liveAvatarSession;
  
  bool _isListening = false;
  bool _showTextInput = false;
  String? _clonedVoiceId;
  String? _testProfilePreviewPath;
  String? _testProfileFaceUrl;
  bool _sessionReady = false;

  final AudioRecorder _voiceRecorder = AudioRecorder();
  StreamSubscription<List<int>>? _voiceStreamSub;
  final List<List<int>> _voicePcmChunks = [];

  static const int _wavSampleRate = 44100;
  static const int _wavChannels = 1;
  static const int _wavBitsPerSample = 16;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionActive && mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _initSession();
  }

  Future<void> _initSession() async {
    final sessionSw = Stopwatch()..start();
    AppLogger.conversation.i('[SESSION][1] _initSession start');
    final isTestProfile = ref.read(testProfileEnabledProvider);
    AppLogger.conversation.d('[SESSION][1] isTestProfile=$isTestProfile');

    if (isTestProfile) {
      final testVoiceId = TestProfileConfig.elevenLabsVoiceId;
      _clonedVoiceId = testVoiceId.isNotEmpty ? testVoiceId : null;
      _testProfilePreviewPath = TestProfileConfig.faceImagePath.isNotEmpty
          ? TestProfileConfig.faceImagePath
          : null;
      AppLogger.conversation.d('[SESSION][2] Test profile — voiceId=$_clonedVoiceId facePath=$_testProfilePreviewPath');

      // Upload face to D-ID at runtime so we get an s3:// URL for streaming.
      final facePath = TestProfileConfig.faceImagePath;
      if (facePath.isNotEmpty) {
        AppLogger.conversation.d('[SESSION][3] Uploading face to D-ID: $facePath');
        try {
          final uploaded = await DidService().uploadImage(facePath);
          if (uploaded != null && uploaded.isNotEmpty) {
            _testProfileFaceUrl = uploaded;
            AppLogger.conversation.i('[SESSION][3] D-ID upload SUCCESS: faceUrl=$_testProfileFaceUrl');
          } else {
            AppLogger.conversation.w('[SESSION][3] D-ID upload returned null/empty — avatar will use fallback');
          }
        } catch (e) {
          AppLogger.conversation.e('[SESSION][3] D-ID upload EXCEPTION', error: e);
        }
      } else {
        AppLogger.conversation.d('[SESSION][3] SKIP D-ID upload — faceImagePath is empty in TestProfileConfig');
      }

      AppLogger.conversation.i('[SESSION][4] Test profile ready — voiceId=$_clonedVoiceId faceUrl=$_testProfileFaceUrl');
    } else {
      AppLogger.conversation.d('[SESSION][2] Real profile — loading from Firestore');
      final user = ref.read(authProvider);
      if (user != null) {
        try {
          await ref.read(avatarProvider.notifier).loadAvatar(user.uid);
        } catch (e) {
          AppLogger.conversation.w('[SESSION][2] loadAvatar FAIL (non-fatal)', error: e);
        }
      }
      final avatar = ref.read(avatarProvider);
      _clonedVoiceId = (avatar?.voiceId.isNotEmpty ?? false) ? avatar!.voiceId : null;
      AppLogger.conversation.d('[SESSION][3] Real profile — voiceId=$_clonedVoiceId faceId=${avatar?.faceId} previewImagePath=${avatar?.previewImagePath}');
    }

    final avatar = ref.read(avatarProvider);
    final avatarId = avatar?.avatarId ?? '';
    AppLogger.conversation.d('[SESSION][5] Starting session — avatarId=$avatarId');
    await ref.read(currentSessionProvider.notifier).startSession(avatarId, 'Participant');
    AppLogger.conversation.i('[SESSION][6] Session started in ${sessionSw.elapsedMilliseconds}ms — _sessionReady=true faceUrl=$_testProfileFaceUrl');
    if (mounted) setState(() => _sessionReady = true);
    _initTts();
    _initAvatarVideo();
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
    for (final chunk in _voicePcmChunks) {
      for (final byte in chunk) {
        out.setUint8(offset++, byte);
      }
    }

    return out.buffer.asUint8List();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopVoiceRecording();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      final hasPermission = await _voiceRecorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }

      await _audioPlayer.stop();
      _voicePcmChunks.clear();

      final stream = await _voiceRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _wavSampleRate,
          numChannels: _wavChannels,
        ),
      );

      _voiceStreamSub = stream.listen((data) {
        _voicePcmChunks.add(data);
      });

      if (!mounted) return;
      setState(() => _isListening = true);
    } catch (e) {
      AppLogger.conversation.e('[VOICE] Start recording error', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
    }
  }

  Future<void> _stopVoiceRecording() async {
    // 1. Detach stream
    _voiceStreamSub?.cancel();
    _voiceStreamSub = null;

    // 2. Fire-and-forget native stop
    _voiceRecorder.stop().timeout(const Duration(seconds: 1), onTimeout: () => null).catchError((_) => null);

    // 3. Build WAV from collected PCM chunks
    int totalPcmBytes = 0;
    for (final chunk in _voicePcmChunks) {
      totalPcmBytes += chunk.length;
    }

    String? wavPath;
    if (totalPcmBytes > 0) {
      final Directory supportDir = await getApplicationSupportDirectory();
      final Directory voiceDir = Directory('${supportDir.path}/voice_input');
      await voiceDir.create(recursive: true);
      wavPath = '${voiceDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      final Uint8List wavBytes = _buildWavFile(totalPcmBytes);
      try {
        await File(wavPath).writeAsBytes(wavBytes, flush: true);
        AppLogger.conversation.d('[VOICE] WAV written: $wavPath (${wavBytes.length} bytes)');
      } catch (e) {
        AppLogger.conversation.e('[VOICE] WAV write failed', error: e);
        wavPath = null;
      }
    }

    _voicePcmChunks.clear();
    if (!mounted) return;
    setState(() => _isListening = false);

    // 4. Transcribe and send
    if (wavPath != null && wavPath.isNotEmpty) {
      try {
        final transcript = await _elevenLabs.transcribeSpeech(wavPath);
        if (transcript.isNotEmpty && mounted) {
          _msgController.text = transcript;
          await _sendMessage();
        }
      } catch (e) {
        AppLogger.conversation.e('[VOICE] Transcription error', error: e);
      }
    }
  }

  Future<void> _initAvatarVideo() async {
    _activeEngine = ref.read(streamingEngineProvider);

    // Wait for Firebase Storage upload to complete (Custom mode only)
    if (ref.read(avatarModeProvider) == AvatarMode.custom) {
      var retries = 0;
      while (retries < 10) {
        final p = ref.read(avatarProvider)?.previewImagePath ?? '';
        if (p.startsWith('http')) break;
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }
    }

    if (_activeEngine == StreamingEngine.dId) {
      // The D-ID WebRTC widget automatically connects on mount
      return;
    }

    if (_activeEngine == StreamingEngine.liveAvatar) {
      final session = await _liveAvatarService.createLiteSession();
      if (session != null && mounted) {
        setState(() => _liveAvatarSession = session);
      }
    }
  }

  Future<void> _initTts() async {
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
    }
    if (_activeEngine == StreamingEngine.dId) {
      // Wait for the D-ID WebRTC stream to be ready before sending intro.
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_didVideoKey.currentState?.isStreamReady == true) break;
      }
      if (mounted && _didVideoKey.currentState?.isStreamReady == true) {
        _speakAsAvatar('Hello, this is me, Omar — but I am now an Avatar. I just moved my consciousness to the internet so I can watch all of your moves.');
      }
    }
  }

  void _addMessage(String text, {required bool isAvatar}) {
    setState(() {
      _messages.add({'text': text, 'isAvatar': isAvatar, 'time': DateTime.now()});
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
    if (isAvatar) {
      _speakAsAvatar(text);
    }
    ref.read(currentSessionProvider.notifier).addTranscriptEntry({
      'text': text,
      'isAvatar': isAvatar,
      'time': DateTime.now().toIso8601String(),
    });
  }

  /// Speaks avatar text using the best available voice source.
  /// D-ID: sends full text script to stream for generation.
  /// LiveAvatar LITE: local ElevenLabs/TTS (WebSocket lip-sync not wired yet).
  Future<void> _speakAsAvatar(String text) async {
    AppLogger.conversation.d('[SPEAK_AVATAR] engine=$_activeEngine text="${text.length > 80 ? text.substring(0, 80) : text}" didVideoReady=${_didVideoKey.currentState != null} clonedVoiceId=$_clonedVoiceId');

    if (_activeEngine == StreamingEngine.dId) {
      final didState = _didVideoKey.currentState;
      AppLogger.conversation.d('[SPEAK_AVATAR] D-ID path — didState=${didState != null ? "ready streamId=${didState.streamId} sessionId=${didState.sessionId}" : "NULL — widget not mounted yet"}');

      // If we have a cloned voice, generate audio with ElevenLabs.
      // Try to upload to Firebase for D-ID lip-sync. If that fails, play locally.
      if (_clonedVoiceId != null && _clonedVoiceId!.isNotEmpty) {
        AppLogger.conversation.d('[SPEAK_AVATAR] ElevenLabs→D-ID audio pipeline — voiceId=$_clonedVoiceId');
        try {
          final audioPath = await _elevenLabs.generateSpeech(text, voiceId: _clonedVoiceId);
          if (audioPath.isNotEmpty) {
            final audioUrl = await _firebaseService.uploadTempAudio(audioPath);
            if (audioUrl != null) {
              AppLogger.conversation.i('[SPEAK_AVATAR] Audio URL ready — passing to D-ID: $audioUrl');
              await didState?.speak(text, audioUrl: audioUrl);
            } else {
              // Firebase upload failed — play locally so user hears their voice
              AppLogger.conversation.w('[SPEAK_AVATAR] Firebase upload failed — playing ElevenLabs audio locally');
              await _audioPlayer.play(DeviceFileSource(audioPath));
            }
            return;
          }
        } catch (e) {
          AppLogger.conversation.e('[SPEAK_AVATAR] ElevenLabs pipeline FAILED — falling back to D-ID TTS', error: e);
        }
      }

      await didState?.speak(text);
      return;
    }

    if (_clonedVoiceId != null && _clonedVoiceId!.isNotEmpty) {
      AppLogger.conversation.d('[SPEAK_AVATAR] ElevenLabs path — voiceId=$_clonedVoiceId');
      try {
        final audioPath = await _elevenLabs.generateSpeech(text, voiceId: _clonedVoiceId);
        AppLogger.conversation.d('[SPEAK_AVATAR] ElevenLabs audioPath="$audioPath"');
        if (audioPath.isNotEmpty) {
          AppLogger.conversation.i('[SPEAK_AVATAR] ElevenLabs speech playing path=$audioPath');
          await _audioPlayer.play(DeviceFileSource(audioPath));
          return;
        }
      } catch (e) {
        AppLogger.conversation.e('[SPEAK_AVATAR] ElevenLabs EXCEPTION — falling back to system TTS', error: e);
      }
    }

    AppLogger.conversation.d('[SPEAK_AVATAR] System TTS fallback');
    _flutterTts.speak(text);
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_sessionActive) return;
    _msgController.clear();
    _addMessage(text, isAvatar: false);
    AppLogger.conversation.d('[SEND] text="$text" engine=$_activeEngine');
    setState(() => _isTyping = true);
    final replySw = Stopwatch()..start();
    try {
      final reply = await _geminiService.generateBehavioralResponse(text);
      AppLogger.conversation.i('[SEND] LLM reply in ${replySw.elapsedMilliseconds}ms replyLen=${reply.length}');
      if (mounted) {
        setState(() => _isTyping = false);
        _addMessage(reply, isAvatar: true);
      }
    } catch (e) {
      AppLogger.conversation.e('[SEND] Claude error', error: e);
      if (mounted) setState(() => _isTyping = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endSession() async {
    AppLogger.conversation.i('_endSession — duration=$_elapsed messagesCount=${_messages.length} engine=$_activeEngine');
    setState(() {
      _sessionActive = false;
      _liveAvatarSession = null;
    });
    _durationTimer?.cancel();
    _flutterTts.stop();
    if (_activeEngine == StreamingEngine.liveAvatar) {
      await _liveAvatarService.stopSession();
    }
    await ref.read(currentSessionProvider.notifier).endSession();
    ref.read(sessionsListProvider.notifier).refresh();
    if (mounted) context.go('/settings');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    _pulse.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _durationTimer?.cancel();
    _voiceStreamSub?.cancel();
    _voiceRecorder.dispose();
    if (_activeEngine == StreamingEngine.liveAvatar) {
      _liveAvatarService.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(avatarProvider);
    final previewPath = avatar?.previewImagePath ?? _testProfilePreviewPath;
    final avatarMode = ref.watch(avatarModeProvider);

    String? customSourceUrl;
    String? customVoiceId;
    String? customVoiceProvider;

    // Test profile always uses custom pipeline (face upload + cloned voice).
    final isTestProfile = ref.watch(testProfileEnabledProvider);
    final useCustomPipeline = avatarMode == AvatarMode.custom || isTestProfile;

    if (useCustomPipeline) {
      final faceId = avatar?.faceId ?? '';
      AppLogger.conversation.d('[BUILD] resolving sourceUrl — _testProfileFaceUrl="$_testProfileFaceUrl" avatar.faceId="$faceId" DID_SOURCE_URL="${AppConfig.didSourceUrl}"');

      if (_testProfileFaceUrl != null && _testProfileFaceUrl!.isNotEmpty) {
        customSourceUrl = _testProfileFaceUrl;
        AppLogger.conversation.d('[BUILD] sourceUrl=RUNTIME_UPLOAD value="$customSourceUrl"');
      } else if (faceId.startsWith('s3://') || faceId.startsWith('https://')) {
        customSourceUrl = faceId;
        AppLogger.conversation.d('[BUILD] sourceUrl=AVATAR_FACE_ID value="$customSourceUrl"');
      } else if (AppConfig.didSourceUrl.isNotEmpty) {
        customSourceUrl = AppConfig.didSourceUrl;
        AppLogger.conversation.d('[BUILD] sourceUrl=ENV_FALLBACK value="$customSourceUrl"');
      } else {
        AppLogger.conversation.w('[BUILD] sourceUrl=NULL — no face URL available, D-ID will use Studio agent');
      }

      final voiceId = avatar?.voiceId ?? '';
      if (voiceId.isNotEmpty) {
        customVoiceId = voiceId;
        customVoiceProvider = 'elevenlabs';
      } else if (_clonedVoiceId != null && _clonedVoiceId!.isNotEmpty) {
        customVoiceId = _clonedVoiceId;
        customVoiceProvider = 'elevenlabs';
      }
      AppLogger.conversation.d('[BUILD] voiceId="$customVoiceId" voiceProvider="$customVoiceProvider"');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_activeEngine == StreamingEngine.dId && _sessionReady)
            Positioned.fill(
              child: DidWebrtcVideo(
                key: _didVideoKey,
                didService: _didService,
                fillScreen: true,
                sourceUrl: customSourceUrl,
                voiceId: customVoiceId,
                voiceProvider: customVoiceProvider,
              ),
            )
          else if (_liveAvatarSession != null)
            Positioned.fill(
              child: LiveKitVideo(
                key: ValueKey(_liveAvatarSession!.sessionId),
                url: _liveAvatarSession!.liveKitUrl,
                token: _liveAvatarSession!.accessToken,
                fillScreen: true,
              ),
            )
          else
            Positioned.fill(
              child: AvatarPreviewDisplay(
                imagePath: previewPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: Container(color: Colors.black),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _blurOrb(PresntTokens.primary.withValues(alpha: 0.12), 220),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _blurOrb(PresntTokens.secondary.withValues(alpha: 0.1), 180),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRESNT',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: PresntTokens.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: PresntTokens.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Color(0x806EDAB4), blurRadius: 8)],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE SESSION · ${_formatDuration(_elapsed)} · B16',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  color: PresntTokens.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        ),
                      ), // end Flexible
                      IconButton(
                        onPressed: () => context.pushNamed(RouteNames.settings),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.25),
                        ),
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _liveAvatarSession == null && _activeEngine != StreamingEngine.dId
                      ? Center(
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final v = _pulse.value;
                              return SizedBox(
                                width: 140,
                                height: 140,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120 + v * 24,
                                      height: 120 + v * 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: PresntTokens.primary.withValues(alpha: 0.22)),
                                      ),
                                    ),
                                    Container(
                                      width: 100 + v * 18,
                                      height: 100 + v * 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: PresntTokens.secondary.withValues(alpha: 0.2)),
                                      ),
                                    ),
                                    const Icon(Icons.graphic_eq_rounded, color: Colors.white24, size: 48),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Bottom glass panel (Stitch design)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status / last message text
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _buildStatusText(),
                                key: ValueKey(_buildStatusText()),
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.90),
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Collapsible text input
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              child: _showTextInput
                                  ? Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _msgController,
                                              enabled: _sessionActive,
                                              autofocus: true,
                                              style: GoogleFonts.inter(color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: 'Type a message…',
                                                hintStyle: const TextStyle(color: Colors.white38),
                                                filled: true,
                                                fillColor: Colors.white.withValues(alpha: 0.10),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(24),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                              ),
                                              onSubmitted: (_) {
                                                _sendMessage();
                                                setState(() => _showTextInput = false);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: _sessionActive
                                                ? () {
                                                    _sendMessage();
                                                    setState(() => _showTextInput = false);
                                                  }
                                                : null,
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: PresntTokens.primary.withValues(alpha: 0.85),
                                              ),
                                              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 22),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Controls row: keyboard | mic | end
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Keyboard toggle
                                _CircleButton(
                                  onTap: () => setState(() => _showTextInput = !_showTextInput),
                                  child: Icon(
                                    _showTextInput ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),

                                // Mic button
                                AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, child) {
                                    return GestureDetector(
                                      onTap: _toggleListening,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (_isListening)
                                            Container(
                                              width: 68,
                                              height: 68,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: PresntTokens.primary.withValues(
                                                  alpha: 0.25 * _pulse.value,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isListening
                                                  ? PresntTokens.primary.withValues(alpha: 0.20)
                                                  : Colors.white.withValues(alpha: 0.10),
                                              border: Border.all(
                                                color: _isListening
                                                    ? PresntTokens.primary.withValues(alpha: 0.7)
                                                    : Colors.white.withValues(alpha: 0.15),
                                              ),
                                            ),
                                            child: Icon(
                                              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                              color: _isListening ? PresntTokens.primary : Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // End call
                                _CircleButton(
                                  onTap: _endSession,
                                  color: PresntTokens.error.withValues(alpha: 0.20),
                                  borderColor: PresntTokens.error.withValues(alpha: 0.30),
                                  child: const Icon(Icons.call_end_rounded, color: PresntTokens.error, size: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildStatusText() {
    if (_isListening) return 'Listening…';
    if (_isTyping) return 'Thinking…';
    if (_messages.isNotEmpty) {
      final last = _messages.last;
      return last['text'] as String;
    }
    return 'Say something…';
  }

  Widget _blurOrb(Color c, double r) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Container(width: r, height: r, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const _CircleButton({required this.onTap, required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.15)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
