import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/streaming_settings_provider.dart';
// AvatarMode and StreamingEngine are both in streaming_settings_provider.dart
import '../../routes/route_names.dart';

class AvatarSetupScreen extends ConsumerWidget {
  const AvatarSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarMode = ref.watch(avatarModeProvider);
    final avatar = ref.watch(avatarProvider);
    final fidelity = (((avatar?.fidelityScore ?? 0.0) * 100)).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Avatar Mode'),
            subtitle: Text(
              avatarMode == AvatarMode.studio
                  ? 'Studio Agent — uses your pre-built D-ID agent'
                  : 'Custom Pipeline — your photo + voice clone',
            ),
            value: avatarMode == AvatarMode.custom,
            onChanged: (val) {
              ref.read(avatarModeProvider.notifier).setMode(
                    val ? AvatarMode.custom : AvatarMode.studio,
                  );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Fidelity Score"),
            trailing: Text("$fidelity%", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          if (avatarMode == AvatarMode.custom) ...[
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
          ],
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
