import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PresntTokens.backgroundLowest,
      body: Stack(
        children: [
          // Ambient blurs
          Positioned(
            top: -80,
            left: -60,
            child: _glowBlob(PresntTokens.primary.withValues(alpha: 0.08), 200),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: _glowBlob(PresntTokens.secondary.withValues(alpha: 0.06), 160),
          ),
          // Editorial radial
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    PresntTokens.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Subtle noise (approximate carbon fibre via opacity layer)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Presnt',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            color: PresntTokens.primary,
                            shadows: [
                              Shadow(
                                color: PresntTokens.primary.withValues(alpha: 0.35),
                                blurRadius: 32,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1,
                              color: PresntTokens.onSurface,
                            ),
                            children: const [
                              TextSpan(text: 'Your AI Self.\n'),
                              TextSpan(
                                text: 'Always Available.',
                                style: TextStyle(color: PresntTokens.onSurfaceVariant),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'The first personal avatar that looks like you, sounds like you, and acts for you.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            height: 1.45,
                            color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: PresntGradientCta(
                            label: 'Get Started',
                            trailing: const Icon(Icons.arrow_forward, color: PresntTokens.onPrimaryFixed),
                            onPressed: () => context.goNamed(RouteNames.createAccount),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar anchor + pulse
                  _AvatarPulse(),
                  const SizedBox(height: 32),

                  // Decorative rings (wide screens)
                  LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth < 600) return const SizedBox.shrink();
                      return const SizedBox(height: 24);
                    },
                  ),

                  Container(height: 1, width: 48, color: PresntTokens.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.goNamed(RouteNames.home),
                    child: Text(
                      'SIGN IN',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: PresntTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(Color c, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      ),
    );
  }
}

class _AvatarPulse extends StatefulWidget {
  @override
  State<_AvatarPulse> createState() => _AvatarPulseState();
}

class _AvatarPulseState extends State<_AvatarPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 112 + _c.value * 8,
              height: 112 + _c.value * 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PresntTokens.primary.withValues(alpha: 0.12 + _c.value * 0.08),
              ),
            ),
            child!,
          ],
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PresntTokens.surfaceContainerHigh,
              border: Border.all(
                color: PresntTokens.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.face_rounded, size: 44, color: PresntTokens.primary),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          PresntTokens.backgroundLowest.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: PresntTokens.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: PresntTokens.backgroundLowest, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: PresntTokens.secondary.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
