import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/approval_token_model.dart';
import '../theme/app_colors.dart';
import '../theme/presnt_tokens.dart';

class ApprovalCard extends StatelessWidget {
  final AuthorizationToken token;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const ApprovalCard({
    super.key,
    required this.token,
    required this.onApprove,
    required this.onDeny,
  });

  String _timeLeft() {
    final remaining = token.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds.remainder(60);
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  bool get _isExpired => DateTime.now().isAfter(token.expiresAt);
  bool get _isUrgent => !_isExpired && token.expiresAt.difference(DateTime.now()).inMinutes < 2;

  String get _urgencyLabel => _isUrgent ? 'HIGH' : 'NORMAL';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: PresntTokens.surfaceContainerHigh.withValues(alpha: 0.85),
              border: Border.all(
                color: _isUrgent
                    ? PresntTokens.tertiaryContainer.withValues(alpha: 0.45)
                    : PresntTokens.outlineVariant.withValues(alpha: 0.12),
                width: _isUrgent ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'URGENCY: $_urgencyLabel',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                color: _isUrgent ? PresntTokens.tertiaryContainer : PresntTokens.secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Credential release',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PresntTokens.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SESSION ID',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              letterSpacing: 1.5,
                              color: PresntTokens.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${token.sessionId.toUpperCase()}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: PresntTokens.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PresntTokens.surfaceContainerLowest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: PresntTokens.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_search_rounded, color: PresntTokens.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REQUESTER',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  color: PresntTokens.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Session participant',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MASKED PREVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: PresntTokens.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          token.credentialType,
                          style: GoogleFonts.robotoMono(
                            fontSize: 18,
                            letterSpacing: 3,
                            color: PresntTokens.primary,
                          ),
                        ),
                      ),
                      const Icon(Icons.visibility_off_outlined, size: 18, color: PresntTokens.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _isUrgent ? PresntTokens.tertiaryContainer : PresntTokens.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expires in ${_timeLeft()} · timeout ${token.timeoutSeconds}s',
                        style: GoogleFonts.inter(fontSize: 12, color: PresntTokens.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDeny,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(
                            'DENY',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [PresntTokens.ctaPurple, PresntTokens.primaryContainer],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: PresntTokens.ctaPurple.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isExpired ? null : onApprove,
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.fingerprint_rounded, color: PresntTokens.onPrimaryFixed, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'APPROVE',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: PresntTokens.onPrimaryFixed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
