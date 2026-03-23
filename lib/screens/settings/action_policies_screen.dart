import 'package:flutter/material.dart';
import '../../widgets/policy_toggle.dart';

class ActionPoliciesScreen extends StatelessWidget {
  const ActionPoliciesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Action Policies")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PolicyToggle(
            title: "Scheduling Meetings",
            currentTier: 1,
            onChanged: (val) {},
          ),
          PolicyToggle(
            title: "Sending Emails",
            currentTier: 2,
            onChanged: (val) {},
          ),
          PolicyToggle(
            title: "Releasing Financial Docs",
            currentTier: 3,
            onChanged: (val) {},
          ),
          const Divider(),
          const Text("Permanently Blocked Actions", style: TextStyle(color: Colors.red)),
          const ListTile(title: Text("Transferring Funds")),
          const ListTile(title: Text("Signing Legal Contracts")),
          const SizedBox(height: 16),
          const Text("Lowering a tier requires biometric authentication.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
