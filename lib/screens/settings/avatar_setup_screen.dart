import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/streaming_settings_provider.dart';
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
            title: const Text('Live video provider'),
            subtitle: const Text('Default: D-ID (d-id.com). Switch to LiveAvatar (liveavatar.com) or HeyGen in .env.'),
            isThreeLine: true,
            trailing: DropdownButton<StreamingEngine>(
              value: ref.watch(streamingEngineProvider),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: StreamingEngine.dId,
                  child: Text('D-ID (d-id.com)'),
                ),
                DropdownMenuItem(
                  value: StreamingEngine.liveAvatar,
                  child: Text('LiveAvatar (liveavatar.com)'),
                ),
                DropdownMenuItem(
                  value: StreamingEngine.heyGen,
                  child: Text('HeyGen'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(streamingEngineProvider.notifier).setEngine(val);
                }
              },
            ),
          ),
          ListTile(
            title: const Text("Fidelity Score"),
            trailing: Text("$fidelity%", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.welcome);
              }
            },
          ),
        ],
      ),
    );
  }
}
