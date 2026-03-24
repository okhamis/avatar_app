import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/credential_tile.dart';
import '../../models/credential_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/approval_provider.dart';

class CredentialsVaultScreen extends ConsumerStatefulWidget {
  const CredentialsVaultScreen({super.key});

  @override
  ConsumerState<CredentialsVaultScreen> createState() => _CredentialsVaultScreenState();
}

class _CredentialsVaultScreenState extends ConsumerState<CredentialsVaultScreen> {
  Future<void> _gateWithBiometric(VoidCallback action) async {
    final biometric = ref.read(biometricServiceProvider);
    final ok = await biometric.authenticate('Authenticate to access your credentials vault');
    if (ok && mounted) {
      action();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication required.')),
      );
    }
  }

  void _showAddCredentialDialog() {
    final typeCtrl = TextEditingController();
    final maskedCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Credential'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(labelText: 'Credential Type (e.g. SSN, Passport)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maskedCtrl,
              decoration: const InputDecoration(labelText: 'Masked Preview (e.g. ***-**-1234)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Raw values are never stored. Only the masked preview is saved here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (typeCtrl.text.trim().isNotEmpty) {
                final now = DateTime.now();
                ref.read(credentialsVaultProvider.notifier).addCredential(CredentialModel(
                  credentialId: 'c_${now.millisecondsSinceEpoch}',
                  accountId: 'acc_1',
                  credentialType: typeCtrl.text.trim(),
                  maskedPreview: maskedCtrl.text.trim().isEmpty ? '****' : maskedCtrl.text.trim(),
                  encryptedReference: 'enc_ref_${now.millisecondsSinceEpoch}',
                  createdAt: now,
                  updatedAt: now,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credentials = ref.watch(credentialsVaultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credentials Vault')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Only masked previews are shown. Raw values are encrypted and never logged.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (credentials.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key, size: 56, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('No credentials stored.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: credentials.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => CredentialTile(
                  credential: credentials[i],
                  onDelete: () => _gateWithBiometric(
                    () => ref.read(credentialsVaultProvider.notifier).removeCredential(credentials[i].credentialId),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _gateWithBiometric(_showAddCredentialDialog),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Credential'),
      ),
    );
  }
}
