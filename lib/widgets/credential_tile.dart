import 'package:flutter/material.dart';
import '../models/credential_model.dart';

class CredentialTile extends StatelessWidget {
  final CredentialModel credential;

  const CredentialTile({Key? key, required this.credential}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: Text(credential.credentialType),
      subtitle: Text("Masked: ${credential.maskedPreview}"),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {},
      ),
    );
  }
}
