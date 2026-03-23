import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class AvatarSetupScreen extends StatelessWidget {
  const AvatarSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const ListTile(
            title: Text("Fidelity Score"),
            trailing: Text("95%", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text("Update Face Photos"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text("Re-record Voice"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text("Update Behavioral Training"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text("Action Policies"),
            onTap: () => context.goNamed(RouteNames.actionPolicies),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Credentials Vault"),
            onTap: () => context.goNamed(RouteNames.credentialsVault),
          ),
          ListTile(
            leading: const Icon(Icons.integration_instructions),
            title: const Text("Integrations"),
            onTap: () => context.goNamed(RouteNames.integrations),
          ),
        ],
      ),
    );
  }
}
