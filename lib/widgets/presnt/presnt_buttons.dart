import 'package:flutter/material.dart';
import '../../theme/presnt_tokens.dart';

class PresntGradientCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const PresntGradientCta({
    super.key,
    required this.label,
    this.onPressed,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: PresntTokens.primaryCtaGradient,
              boxShadow: [
                if (enabled)
                  BoxShadow(
                    color: PresntTokens.primaryContainer.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: PresntTokens.onPrimaryFixed,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PresntSecondaryPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const PresntSecondaryPillButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: PresntTokens.onSurface,
        side: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.2)),
        backgroundColor: PresntTokens.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: PresntTokens.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
