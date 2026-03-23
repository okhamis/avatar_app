import 'package:flutter/material.dart';
import '../../widgets/credential_tile.dart';
import '../../models/credential_model.dart';

class CredentialsVaultScreen extends StatelessWidget {
  const CredentialsVaultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mockCred = CredentialModel(
      credentialId: "c_1",
      accountId: "a_1",
      credentialType: "SSN",
      maskedPreview: "***-**-1234",
      encryptedReference: "ref_abc",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Credentials Vault")),
      body: ListView(
        children: [
          CredentialTile(credential: mockCred),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
