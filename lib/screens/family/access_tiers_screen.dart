import 'package:flutter/material.dart';

class AccessTiersScreen extends StatelessWidget {
  const AccessTiersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Access Tiers")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text("Tier 1: Autonomous"),
            subtitle: Text("Avatar responds entirely on its own."),
          ),
          ListTile(
            title: Text("Tier 2: Notify"),
            subtitle: Text("Avatar responds but notifies you."),
          ),
          ListTile(
            title: Text("Tier 3: Wait for Approval"),
            subtitle: Text("Avatar stalls until biometric approval."),
          ),
          ListTile(
            title: Text("Blocked"),
            subtitle: Text("Avatar refuses the request."),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
