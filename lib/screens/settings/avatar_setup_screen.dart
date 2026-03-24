import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/avatar_provider.dart';
import '../../routes/route_names.dart';

class AvatarSetupScreen extends ConsumerWidget {
  const AvatarSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarProvider);
    final fidelity = (((avatar?.fidelityScore ?? 0.0) * 100)).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: Text("Fidelity Score"),
            trailing: Text("$fidelity%", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text("Update Face Photos"),
            onTap: () => context.goNamed(RouteNames.faceUpload),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text("Re-record Voice"),
            onTap: () => context.goNamed(RouteNames.voiceRecord),
          ),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text("Update Behavioral Training"),
            onTap: () => context.goNamed(RouteNames.behavioralTraining),
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
