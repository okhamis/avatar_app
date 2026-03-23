import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_glass_bar.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  State<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> with TickerProviderStateMixin {
  bool _isRecording = false;
  double _progress = 0.0;
  Timer? _timer;
  late final List<AnimationController> _waveCtrls;

  static const _sample =
      '"My digital presence is an extension of my identity. This voice represents my thoughts, my values, and my unique perspective in the digital world. I am Presnt."';

  @override
  void initState() {
    super.initState();
    _waveCtrls = List.generate(
      11,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 650 + (i * 37 % 280)),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _waveCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _progress = 0.0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _progress += 0.012;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _stopRecording();
        }
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    final complete = _progress >= 1.0;
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      extendBodyBehindAppBar: true,
      appBar: PresntGlassTopBar(
        leading: IconButton(
          onPressed: () => context.pop(),
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
            onPressed: () {},
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
                        _sample,
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
                                height: _isRecording ? h : 8 + (i % 4) * 2.0,
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
                      onTap: _toggleRecording,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
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
                          onPressed: () => setState(() => _progress = 0),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: PresntGradientCta(
              label: 'Continue to Analysis',
              onPressed: complete ? () => context.goNamed(RouteNames.behavioralTraining) : null,
              padding: const EdgeInsets.symmetric(vertical: 18),
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
          child: const Icon(Icons.mic_rounded, size: 44, color: PresntTokens.onPrimaryFixed),
        ),
      ),
    );
  }
}
