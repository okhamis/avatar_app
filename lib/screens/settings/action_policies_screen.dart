import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/policy_toggle.dart';
import '../../models/policy_record_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/approval_provider.dart';

class ActionPoliciesScreen extends ConsumerStatefulWidget {
  const ActionPoliciesScreen({super.key});

  @override
  ConsumerState<ActionPoliciesScreen> createState() => _ActionPoliciesScreenState();
}

class _ActionPoliciesScreenState extends ConsumerState<ActionPoliciesScreen> {
  Future<void> _changeTier(PolicyRecord policy, int newTier) async {
    // Lowering a tier requires biometric
    if (newTier < policy.effectiveTier) {
      final biometric = ref.read(biometricServiceProvider);
      final ok = await biometric.authenticate(
        'Lowering the approval tier for "${policy.actionType}" requires your biometric.',
      );
      if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric required to lower a tier.')),
        );
      }
      return;
    }
    if (!mounted) return;
    }
    ref.read(policiesProvider.notifier).updatePolicyTier(policy.recordId, newTier);
  }

  @override
  Widget build(BuildContext context) {
    final policies = ref.watch(policiesProvider);
    final activePolicies = policies.where((p) => !p.permanentlyBlocked).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Action Policies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Set which tier of approval is required for each action type. '
              'Lowering a tier requires biometric authentication.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          if (activePolicies.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No action policies yet. Add policies from settings or sync from your account when the backend is connected.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            const Text('Configurable Policies', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...activePolicies.map((policy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PolicyToggle(
                title: policy.actionType,
                currentTier: policy.effectiveTier,
                onChanged: (tier) => _changeTier(policy, tier),
              ),
            )),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Permanently Blocked Actions',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _blockedTile('Transferring Funds'),
          _blockedTile('Signing Legal Contracts'),
          _blockedTile('Updating Biometric Records'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Permanently blocked actions can never be performed by your avatar. '
              'They are locked by system policy and cannot be overridden.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockedTile(String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.block, color: AppColors.danger, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Text('Blocked', style: TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}
