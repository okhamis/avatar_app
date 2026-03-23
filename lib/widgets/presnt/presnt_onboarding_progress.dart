import 'package:flutter/material.dart';
import '../../theme/presnt_tokens.dart';

class PresntOnboardingProgress extends StatelessWidget {
  final int step;
  final int total;
  final String? rightLabel;

  const PresntOnboardingProgress({
    super.key,
    required this.step,
    this.total = 6,
    this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = (step / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $step OF $total',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: PresntTokens.primary.withValues(alpha: 0.6),
              ),
            ),
            if (rightLabel != null)
              Text(
                rightLabel!.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: PresntTokens.surfaceContainerHigh),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PresntTokens.primary,
                          PresntTokens.primaryContainer,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
