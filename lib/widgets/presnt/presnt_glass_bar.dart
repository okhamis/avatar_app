import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/presnt_tokens.dart';

class PresntGlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double height;

  const PresntGlassTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.height = 72,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final actionWidgets = actions ?? const <Widget>[];
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: PresntTokens.surface.withValues(alpha: 0.6),
            boxShadow: [
              BoxShadow(
                color: PresntTokens.primary.withValues(alpha: 0.04),
                blurRadius: 64,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: leading ?? const SizedBox.shrink(),
                  ),
                ),
                Expanded(
                  child: Center(child: title ?? const SizedBox.shrink()),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actionWidgets,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
