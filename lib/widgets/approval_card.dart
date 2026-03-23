import 'package:flutter/material.dart';
import '../models/approval_token_model.dart';

class ApprovalCard extends StatelessWidget {
  final AuthorizationToken token;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const ApprovalCard({
    Key? key,
    required this.token,
    required this.onApprove,
    required this.onDeny,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Request: ${token.credentialType}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Session ID: ${token.sessionId}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDeny,
                  child: const Text("Deny", style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text("Approve (Biometric)"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
