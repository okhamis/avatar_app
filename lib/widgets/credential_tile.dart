import 'package:flutter/material.dart';
import '../models/credential_model.dart';
import '../theme/app_colors.dart';

class CredentialTile extends StatelessWidget {
  final CredentialModel credential;
  final VoidCallback? onDelete;

  const CredentialTile({super.key, required this.credential, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.vpn_key, color: AppColors.primary, size: 20),
      ),
      title: Text(credential.credentialType),
      subtitle: Text(
        credential.maskedPreview,
        style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace'),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
              tooltip: 'Delete (requires biometric)',
            )
          : null,
    );
  }
}
