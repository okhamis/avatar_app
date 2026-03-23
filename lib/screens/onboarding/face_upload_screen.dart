import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/presnt/presnt_glass_bar.dart';
import '../../widgets/presnt/presnt_onboarding_progress.dart';

class FaceUploadScreen extends ConsumerStatefulWidget {
  const FaceUploadScreen({
    super.key,
    this.initialPhotos = const [],
    this.renderPhotoThumbnails = true,
  });

  final List<XFile> initialPhotos;
  final bool renderPhotoThumbnails;

  @override
  ConsumerState<FaceUploadScreen> createState() => _FaceUploadScreenState();
}

class _FaceUploadScreenState extends ConsumerState<FaceUploadScreen> {
  static const int kMax = 10;
  static const int kMin = 5;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPhotos.isNotEmpty) {
      _photos.addAll(widget.initialPhotos.take(kMax));
    }
  }

  Future<void> _pickGallery() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      setState(() {
        for (final img in images) {
          if (_photos.length >= kMax) break;
          _photos.add(img);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickCamera() async {
    try {
      if (_photos.length >= kMax) return;
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _photos.add(photo));
      }
    } catch (_) {
      await _pickGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _photos.length >= kMin;
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      extendBodyBehindAppBar: true,
      appBar: PresntGlassTopBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.menu_rounded, color: PresntTokens.primary),
        ),
        title: Text(
          'Presnt',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: PresntTokens.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: PresntTokens.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 72),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PresntOnboardingProgress(step: 2, rightLabel: 'Identity Build'),
                  const SizedBox(height: 28),
                  Text(
                    "Let's build your face",
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: PresntTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload 5 to 10 photos for the best representation. Our AI requires diverse angles to craft your digital double.',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      height: 1.45,
                      color: PresntTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _bentoGrid(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _camGalleryButton(Icons.photo_camera_rounded, 'Camera', _pickCamera)),
                      const SizedBox(width: 14),
                      Expanded(child: _camGalleryButton(Icons.photo_library_rounded, 'Gallery', _pickGallery)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _tipsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                PresntTokens.surface,
                PresntTokens.surface.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () async {
                          final user = ref.read(authProvider);
                          if (user == null) return;
                          final paths = _photos.map((p) => p.path).toList();
                          try {
                            await ref.read(avatarProvider.notifier).saveFaceDraft(ownerId: user.uid, imagePaths: paths);
                            await ref.read(authProvider.notifier).updateTrainingFlags(hasFaceTrained: true);
                            if (!context.mounted) return;
                            context.goNamed(RouteNames.voiceRecord);
                          } catch (_) {
                            if (!context.mounted) return;
                            if (kDebugMode) {
                              // Keep local demo flow unblocked when backend wiring is absent.
                              context.goNamed(RouteNames.voiceRecord);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('We could not process photos right now. Please try again.')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: canContinue ? PresntTokens.ctaPurple : PresntTokens.surfaceContainerHighest,
                    foregroundColor: canContinue ? Colors.white : PresntTokens.onSurfaceVariant.withValues(alpha: 0.4),
                    disabledBackgroundColor: PresntTokens.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20, color: canContinue ? Colors.white : PresntTokens.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                canContinue
                    ? 'Ready to proceed to the next step'
                    : 'Upload at least $kMin photos to continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: PresntTokens.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bentoGrid() {
    return LayoutBuilder(
      builder: (context, c) {
        final W = c.maxWidth;
        const g = 12.0;
        final s = (W - 2 * g) / 3;
        final big = 2 * s + g;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: big,
                  height: big,
                  child: _slot(0, isPrimary: true),
                ),
                SizedBox(width: g),
                Column(
                  children: [
                    SizedBox(width: s, height: s, child: _slot(1)),
                    SizedBox(height: g),
                    SizedBox(width: s, height: s, child: _slot(2)),
                  ],
                ),
              ],
            ),
            SizedBox(height: g),
            Row(
              children: [
                SizedBox(width: s, height: s, child: _slot(3)),
                SizedBox(width: g),
                SizedBox(width: s, height: s, child: _slot(4)),
                SizedBox(width: g),
                SizedBox(width: s, height: s, child: _slot(5)),
              ],
            ),
            SizedBox(height: g),
            Row(
              children: [
                SizedBox(width: s, height: s, child: _slot(6)),
                SizedBox(width: g),
                SizedBox(width: s, height: s, child: _slot(7)),
                SizedBox(width: g),
                SizedBox(width: s, height: s, child: _slot(8)),
              ],
            ),
            SizedBox(height: g),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: s, height: s, child: _slot(9)),
            ),
          ],
        );
      },
    );
  }

  Widget _slot(int index, {bool isPrimary = false}) {
    final has = index < _photos.length;
    final radius = isPrimary ? 28.0 : 18.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickGallery,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: PresntTokens.backgroundLowest,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: PresntTokens.outlineVariant.withValues(alpha: isPrimary ? 0.35 : 0.22),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 2),
            child: has
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.renderPhotoThumbnails
                          ? Image.file(
                              File(_photos[index].path),
                              fit: BoxFit.cover,
                            )
                          : Container(color: PresntTokens.surfaceContainerHigh),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: PresntTokens.secondary, size: 16),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPrimary ? Icons.add_a_photo_outlined : Icons.add_rounded,
                        size: isPrimary ? 40 : 28,
                        color: isPrimary
                            ? PresntTokens.primary.withValues(alpha: 0.45)
                            : PresntTokens.outlineVariant,
                      ),
                      if (isPrimary) ...[
                        const SizedBox(height: 6),
                        Text(
                          'PRIMARY ANGLE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _camGalleryButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: PresntTokens.onSurface,
        backgroundColor: PresntTokens.surfaceContainerHigh,
        side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: PresntTokens.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    Widget tip(IconData i, Color ic, String t, String s) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PresntTokens.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(i, size: 18, color: ic),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  s,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    height: 1.35,
                    color: PresntTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PresntTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: PresntTokens.secondary),
              const SizedBox(width: 8),
              Text(
                'Pro Tips for Accuracy',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 22),
          tip(
            Icons.light_mode_outlined,
            PresntTokens.secondary,
            'Natural Lighting',
            'Avoid harsh shadows or backlighting. Soft daylight works best.',
          ),
          const SizedBox(height: 18),
          tip(
            Icons.block_rounded,
            PresntTokens.tertiary,
            'No Obstructions',
            'Remove sunglasses, hats, or masks that hide your facial features.',
          ),
          const SizedBox(height: 18),
          tip(
            Icons.groups_2_outlined,
            PresntTokens.primary,
            'Show Variety',
            'Upload photos with different expressions and head angles.',
          ),
        ],
      ),
    );
  }
}
