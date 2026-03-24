import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/approval_card.dart';
import '../../providers/approval_provider.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends ConsumerState<PendingApprovalsScreen> {
  @override
  Widget build(BuildContext context) {
    final approvals = ref.watch(pendingApprovalsProvider).where((t) => !t.used && !t.invalidated).toList();

    return Scaffold(
      backgroundColor: PresntTokens.background,
      body: Column(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 16),
                decoration: BoxDecoration(
                  color: PresntTokens.surface.withValues(alpha: 0.55),
                  boxShadow: [
                    BoxShadow(
                      color: PresntTokens.primary.withValues(alpha: 0.04),
                      blurRadius: 48,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: PresntTokens.surfaceContainerHigh,
                          child: const Icon(Icons.hub_rounded, color: PresntTokens.primary),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: PresntTokens.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: PresntTokens.surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Digital Concierge',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PresntTokens.primary,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.fingerprint_rounded, color: PresntTokens.primary, size: 28),
                        ),
                        if (approvals.isNotEmpty)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PresntTokens.tertiaryContainer,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: PresntTokens.surface, width: 2),
                              ),
                              child: Text(
                                '${approvals.length}',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: PresntTokens.onPrimaryContainer),
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
          Expanded(
            child: approvals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 64, color: PresntTokens.secondary),
                                const SizedBox(height: 16),
                                Text(
                                  'All caught up',
                                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No pending approvals.',
                                  style: GoogleFonts.manrope(color: PresntTokens.onSurfaceVariant),
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: () => context.goNamed(RouteNames.approvalHistory),
                                  child: const Text('View history'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                            children: [
                              Text(
                                'SECURITY GATEWAY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                  color: PresntTokens.primary.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Pending\nApprovals',
                                      style: GoogleFonts.manrope(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: PresntTokens.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: PresntTokens.tertiary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${approvals.length} Pending',
                                          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Verify outgoing credential requests from your AI agent sessions.',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: PresntTokens.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ...approvals.map(
                                (token) => ApprovalCard(
                                  token: token,
                                  onApprove: () async {
                                    final approved = await ref.read(pendingApprovalsProvider.notifier).approveRequest(
                                          token.tokenId,
                                          'Approve credential release for this active session.',
                                        );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          approved ? 'Approved with biometric confirmation.' : 'Biometric confirmation failed.',
                                        ),
                                        backgroundColor: approved ? PresntTokens.secondary : AppColors.danger,
                                      ),
                                    );
                                  },
                                  onDeny: () {
                                    ref.read(pendingApprovalsProvider.notifier).denyRequest(token.tokenId);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request denied.')));
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 16, color: PresntTokens.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'END-TO-END BIOMETRIC VERIFICATION REQUIRED',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
