import 'package:flutter/material.dart';
import '../../widgets/approval_card.dart';
import '../../models/approval_token_model.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mockToken = AuthorizationToken(
      tokenId: "tk_1",
      accountId: "ac_1",
      sessionId: "sess_1",
      credentialType: "SSN (Last 4)",
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      timeoutSeconds: 300,
      used: false,
      invalidated: false,
      biometricRef: "bio_1",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Approvals (1)"),
      ),
      body: ListView(
        children: [
          ApprovalCard(
            token: mockToken,
            onApprove: () {},
            onDeny: () {},
          )
        ],
      ),
    );
  }
}
