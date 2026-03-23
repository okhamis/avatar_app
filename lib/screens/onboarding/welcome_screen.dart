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
    final w = MediaQuery.sizeOf(context).width;
    final maxContent = w.clamp(0.0, 960.0);

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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContent),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    (w * 0.06).clamp(20.0, 56.0),
                    32,
                    (w * 0.06).clamp(20.0, 56.0),
                    16,
                  ),
                  child: Column(
                    children: [
                      // Scroll when the window is short (macOS default size); avoids RenderFlex overflow.
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Presnt',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: (44 * (w / 390).clamp(1.0, 1.35)).clamp(40.0, 64.0),
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
                                    SizedBox(height: (w / 390).clamp(1.0, 1.2) * 32),
                                    Text.rich(
                                      TextSpan(
                                        style: GoogleFonts.manrope(
                                          fontSize: (28 * (w / 390).clamp(1.0, 1.25)).clamp(26.0, 40.0),
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
                                    SizedBox(height: (w / 390).clamp(1.0, 1.15) * 16),
                                    Text(
                                      'The first personal avatar that looks like you, sounds like you, and acts for you.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: (16 * (w / 390).clamp(1.0, 1.12)).clamp(15.0, 20.0),
                                        height: 1.45,
                                        color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    SizedBox(height: (w / 390).clamp(1.0, 1.15) * 28),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: (w * 0.85).clamp(280.0, 420.0),
                                      ),
                                      child: PresntGradientCta(
                                        label: 'Get Started',
                                        trailing: const Icon(Icons.arrow_forward, color: PresntTokens.onPrimaryFixed),
                                        onPressed: () => context.goNamed(RouteNames.createAccount),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                    onPressed: () => context.goNamed(RouteNames.signIn),
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
