import 'dart:io';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/presnt_tokens.dart';

/// Renders [imagePath] from disk, network URL, or optional [fallbackNetworkUrl], then [placeholder].
class AvatarPreviewDisplay extends StatelessWidget {
  const AvatarPreviewDisplay({
    super.key,
    required this.imagePath,
    this.fallbackNetworkUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
  });

  final String? imagePath;
  final String? fallbackNetworkUrl;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Widget? placeholder;

  Widget _defaultPlaceholder() {
    return Container(
      color: PresntTokens.surfaceContainerLowest,
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, size: 80, color: PresntTokens.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ph = placeholder ?? _defaultPlaceholder();

    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('http')) {
        return Image.network(
          imagePath!,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, _, _) => _buildFallback(ph),
        );
      }
      final file = File(imagePath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (ctx, snap) {
          if (snap.data == true) {
            return Image.file(file, fit: fit, alignment: alignment);
          }
          return _buildFallback(ph);
        },
      );
    }

    return _buildFallback(ph);
  }

  Widget _buildFallback(Widget ph) {
    final url = fallbackNetworkUrl ?? AppConfig.placeholderPortraitUrl;
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => ph,
      );
    }
    return ph;
  }
}
