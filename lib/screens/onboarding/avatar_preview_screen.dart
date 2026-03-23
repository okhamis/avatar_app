import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/avatar_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_glass_bar.dart';
import '../../widgets/presnt/presnt_buttons.dart';

class AvatarPreviewScreen extends ConsumerWidget {
  const AvatarPreviewScreen({super.key});

  static const _previewUrl =
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&h=800&fit=crop';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarProvider);
    final fidelityLabel = '${(((avatar?.fidelityScore ?? 0.984) * 100)).toStringAsFixed(1)}%';
    final livePreview = avatar?.previewImagePath;
    final previewUrl = (livePreview != null && livePreview.startsWith('http')) ? livePreview : _previewUrl;
    return Scaffold(
      backgroundColor: PresntTokens.background,
      extendBodyBehindAppBar: true,
      appBar: PresntGlassTopBar(
        height: 72,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: PresntTokens.surfaceContainerHigh,
          child: ClipOval(
            child: Image.network(
              previewUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, color: PresntTokens.onSurfaceVariant),
            ),
          ),
        ),
        title: Text(
          'PRESNT',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: PresntTokens.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_suggest_outlined, color: PresntTokens.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 88, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 06 OF 06',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: PresntTokens.outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Meet your avatar',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: PresntTokens.onSurface,
                      ),
                    ),
                  ],
                ),
                _stepDots(),
              ],
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 900;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 58, child: _previewPane(context, previewUrl)),
                      const SizedBox(width: 28),
                      Expanded(flex: 42, child: _sidePanel(context, fidelityLabel)),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _previewPane(context, previewUrl),
                    const SizedBox(height: 24),
                    _sidePanel(context, fidelityLabel),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: PresntTokens.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PresntTokens.secondary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: PresntTokens.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SYSTEM OPTIMIZED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: PresntTokens.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline_rounded, color: PresntTokens.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepDots() {
    return Row(
      children: List.generate(6, (i) {
        final active = i == 5;
        return Container(
          margin: const EdgeInsets.only(left: 6),
          width: active ? 28 : 22,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active ? PresntTokens.primary : PresntTokens.surfaceContainerHighest,
          ),
        );
      }),
    );
  }

  Widget _previewPane(BuildContext context, String previewUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: PresntTokens.surfaceContainerLowest,
                    child: const Icon(Icons.person_rounded, size: 80, color: PresntTokens.primary),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: PresntTokens.secondary.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: PresntTokens.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RENDERING LIVE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                                color: PresntTokens.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                      border: Border.all(color: PresntTokens.primary.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 44, color: PresntTokens.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: PresntTokens.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: const Border(
              left: BorderSide(color: PresntTokens.primary, width: 3),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.format_quote_rounded, size: 56, color: PresntTokens.onSurface.withValues(alpha: 0.06)),
              ),
              Text(
                '"Hi, I am your Presnt avatar. I am ready to represent you."',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: PresntTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidePanel(BuildContext context, String fidelityLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: PresntTokens.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: (double.tryParse(fidelityLabel.replaceAll('%', '')) ?? 98.4) / 100,
                        strokeWidth: 8,
                        backgroundColor: PresntTokens.surfaceContainerHighest,
                        color: PresntTokens.secondary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fidelityLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: PresntTokens.onSurface,
                          ),
                        ),
                        Text(
                          'FIDELITY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: PresntTokens.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'High Precision Output',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Our neural engine has matched your biometric patterns with exceptional accuracy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.45,
                  color: PresntTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PresntGradientCta(
          label: 'Approve and Go Live',
          onPressed: () => context.goNamed(RouteNames.goLive),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: PresntTokens.onSurface,
                  side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('RE-TRAIN', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: PresntTokens.onSurface,
                  side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                label: Text('ADJUST', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PresntTokens.surfaceContainerLowest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: PresntTokens.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Going live will sync your avatar across all active Presence channels. You can pause or revoke access anytime in core settings.',
                  style: GoogleFonts.manrope(fontSize: 12, height: 1.45, color: PresntTokens.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
