import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/session_provider.dart';
import '../../models/avatar_model.dart';
import '../../widgets/avatar_preview_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final avatar = ref.watch(avatarProvider);
    final conversationCount = ref.watch(sessionsListProvider).length;

    final name = user?.fullName ?? 'Your Avatar';
    final status = (avatar?.status ?? AvatarStatus.draft).name;
    final fidelityPct = ((avatar?.fidelityScore ?? 0.0) * 100).round();
    final previewPath = avatar?.previewImagePath;

    return Scaffold(
      backgroundColor: PresntTokens.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AvatarPreviewDisplay(
              imagePath: previewPath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: Container(
                color: PresntTokens.surfaceContainerLowest,
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 120, color: PresntTokens.primary),
                ),
              ),
            ),
          ),
          // Vignette + gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  PresntTokens.background.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PresntTokens.surface.withValues(alpha: 0.45),
                  Colors.transparent,
                  PresntTokens.surface.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PresntTokens.primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: PresntTokens.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x806EDAB4), blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status == 'live' ? 'READY' : status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: PresntTokens.secondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'PRESNT',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                      color: PresntTokens.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.goNamed(RouteNames.settings),
                    icon: Icon(Icons.settings_suggest_outlined, color: PresntTokens.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONAL CONCIERGE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                        color: PresntTokens.primary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        shadows: const [Shadow(blurRadius: 24, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: _miniStat('CONVERSATIONS', '$conversationCount', PresntTokens.primary)),
                        Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.12)),
                        Expanded(child: _miniStat('FIDELITY', '$fidelityPct%', Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pushNamed(RouteNames.liveConversation),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Conversation',
                                            style: GoogleFonts.manrope(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to initialize neural link',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              letterSpacing: 1.5,
                                              color: PresntTokens.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: PresntTokens.primary.withValues(alpha: 0.22),
                                      ),
                                      child: const Icon(Icons.mic_rounded, color: PresntTokens.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.goNamed(RouteNames.conversations),
                      child: Text(
                        'View history',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: PresntTokens.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
