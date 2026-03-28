import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/approval_provider.dart';
import '../../models/approval_token_model.dart';

class ApprovalHistoryScreen extends ConsumerStatefulWidget {
  const ApprovalHistoryScreen({super.key});

  @override
  ConsumerState<ApprovalHistoryScreen> createState() => _ApprovalHistoryScreenState();
}

class _ApprovalHistoryScreenState extends ConsumerState<ApprovalHistoryScreen> {
  String _filter = 'All';

  String _outcome(AuthorizationToken t) {
    if (t.used) return 'approved';
    if (t.invalidated) return 'denied';
    if (t.expiresAt.isBefore(DateTime.now())) return 'expired';
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(pendingApprovalsProvider);
    final resolved = all.where((t) => t.used || t.invalidated || t.expiresAt.isBefore(DateTime.now())).toList();

    final items = _filter == 'All'
        ? resolved
        : resolved.where((t) => _outcome(t) == _filter.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Approval History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: ['All', 'Approved', 'Denied', 'Expired'].map((label) {
                final active = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = label),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: active ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No approval history yet. Completed approvals will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final token = items[i];
                      final outcome = _outcome(token);
                      return ListTile(
                        leading: _outcomeIcon(outcome),
                        title: Text(token.credentialType),
                        subtitle: Text('Session: ${token.sessionId.substring(0, 8)}… · ${_formatTime(token.issuedAt)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _outcomeColor(outcome).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            outcome[0].toUpperCase() + outcome.substring(1),
                            style: TextStyle(
                              color: _outcomeColor(outcome),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _outcomeIcon(String outcome) {
    switch (outcome) {
      case 'approved':
        return const CircleAvatar(
          backgroundColor: AppColors.statusActive,
          radius: 18,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        );
      case 'denied':
        return const CircleAvatar(
          backgroundColor: AppColors.danger,
          radius: 18,
          child: Icon(Icons.close, color: Colors.white, size: 16),
        );
      default:
        return const CircleAvatar(
          backgroundColor: AppColors.statusSleeping,
          radius: 18,
          child: Icon(Icons.timer_off, color: Colors.white, size: 16),
        );
    }
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'approved':
        return AppColors.statusActive;
      case 'denied':
        return AppColors.danger;
      default:
        return AppColors.statusSleeping;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
