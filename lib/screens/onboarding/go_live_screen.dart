import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class GoLiveScreen extends StatelessWidget {
  const GoLiveScreen({super.key});

  static const _artUrl =
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&h=600&fit=crop';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _glow(const Color(0x26C5C0FF), 280),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _glow(const Color(0x1A6EDAB4), 240),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PresntTokens.secondary.withValues(alpha: 0.25), width: 2),
                        ),
                      ),
                      Container(
                        width: 200,
                        height: 200,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [PresntTokens.primary, PresntTokens.secondary],
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PresntTokens.surface,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: Image.network(
                              _artUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: PresntTokens.surfaceContainerLowest,
                                child: const Icon(Icons.hub_rounded, size: 72, color: PresntTokens.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'YOU ARE LIVE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: PresntTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your avatar is ready to represent you',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      letterSpacing: 0.5,
                      color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(child: _glassTile(Icons.face_rounded, 'Face Trained')),
                      const SizedBox(width: 12),
                      Expanded(child: _glassTile(Icons.graphic_eq_rounded, 'Voice Cloned')),
                      const SizedBox(width: 12),
                      Expanded(child: _glassTile(Icons.psychology_rounded, 'Personality Modeled')),
                    ],
                  ),
                  const Spacer(),
                  PresntGradientCta(
                    label: 'Enter Presnt',
                    onPressed: () => context.goNamed(RouteNames.home),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DIGITAL CONCIERGE SYSTEMS ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 3,
                      color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.4),
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

  Widget _glow(Color c, double r) {
    return Container(
      width: r,
      height: r,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    );
  }

  Widget _glassTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: PresntTokens.surfaceBright.withValues(alpha: 0.35),
        border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: PresntTokens.secondary, size: 30),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: PresntTokens.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
