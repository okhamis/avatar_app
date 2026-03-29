import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/test_profile_config.dart';
import '../../core/providers/service_providers.dart';
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

    final testProfileEnabled = ref.watch(testProfileEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Test Profile'),
            subtitle: Text(
              testProfileEnabled 
                  ? 'Skip onboarding and use Omar test profile'
                  : 'Manually capture face, voice, and behavior',
            ),
            value: testProfileEnabled,
            onChanged: (val) async {
              await ref.read(testProfileEnabledProvider.notifier).setEnabled(val);
              final user = ref.read(authProvider);

              if (val && user != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Applying Test Profile...'))
                  );
                }
                
                final path = TestProfileConfig.faceImagePath;
                final file = File(path);
                
                final publicUrl = await ref.read(firebaseServiceProvider).uploadAvatarPreviewImage(
                  ownerId: user.uid,
                  file: file,
                );
                
                await ref.read(avatarProvider.notifier).saveFaceDraft(
                  ownerId: user.uid, 
                  imagePaths: [publicUrl ?? path, publicUrl ?? path, publicUrl ?? path, publicUrl ?? path, publicUrl ?? path],
                );
                
                await ref.read(avatarProvider.notifier).trainBehaviorProfile(
                  ownerId: user.uid, 
                  answers: TestProfileConfig.behavioralAnswers,
                );
                
                await ref.read(authProvider.notifier).updateTrainingFlags(
                  hasFaceTrained: true,
                  hasVoiceCloned: true,
                  hasBehaviorTrained: true,
                );
                
                if (context.mounted) {
                   ScaffoldMessenger.of(context).hideCurrentSnackBar();
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Profile Applied!')));
                }
              } else if (!val && user != null) {
                await ref.read(authProvider.notifier).updateTrainingFlags(
                  hasFaceTrained: false,
                  hasVoiceCloned: false,
                  hasBehaviorTrained: false,
                );
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Profile Disabled. Manual capture required.')));
                }
              }
            },
          ),
          const Divider(),
          // --- STUDIO MODE DISABLED ---
          // SwitchListTile(
          //   title: const Text('Avatar Mode'),
          //   subtitle: Text(
          //     avatarMode == AvatarMode.studio
          //         ? 'Use a pre-made avatar from our studio'
          //         : 'Create a custom avatar with your face and voice',
          //   ),
          //   value: avatarMode == AvatarMode.custom,
          //   onChanged: (val) async {
          //     final mode = val ? AvatarMode.custom : AvatarMode.studio;
          //     await ref.read(avatarModeProvider.notifier).setMode(mode);
          //     if (mode == AvatarMode.custom) {
          //       // Reset training flags to force full onboarding
          //       await ref.read(authProvider.notifier).updateTrainingFlags(
          //         hasFaceTrained: false,
          //         hasVoiceCloned: false,
          //         hasBehaviorTrained: false,
          //       );
          //       await ref.read(streamingEngineProvider.notifier).setEngine(StreamingEngine.dId);
          //     }
          //   },
          // ),
          // const Divider(),
          ListTile(
            title: const Text("Fidelity Score"),
            trailing: Text("$fidelity%", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          // if (avatarMode == AvatarMode.custom) ...[
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
          // ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat History'),
            subtitle: const Text('View past conversations'),
            onTap: () => context.pushNamed(RouteNames.conversations),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('View Logs'),
            subtitle: const Text('In-app log viewer'),
            onTap: () => context.pushNamed(RouteNames.logViewer),
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
