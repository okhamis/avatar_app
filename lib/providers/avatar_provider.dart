import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar_model.dart';
import '../services/heygen_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/claude_service.dart';

final heygenProvider = Provider((ref) => HeyGenService());
final elevenlabsProvider = Provider((ref) => ElevenLabsService());
final claudeProvider = Provider((ref) => ClaudeService());

final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarModel?>((ref) {
  return AvatarNotifier(
    ref.watch(heygenProvider),
    ref.watch(elevenlabsProvider),
    ref.watch(claudeProvider),
  );
});

class AvatarNotifier extends StateNotifier<AvatarModel?> {
  final HeyGenService heyGen;
  final ElevenLabsService elevenLabs;
  final ClaudeService claude;

  AvatarNotifier(this.heyGen, this.elevenLabs, this.claude) : super(null);

  Future<void> createAvatar(String ownerId) async {
    await Future.delayed(const Duration(seconds: 2));
    state = AvatarModel(
      avatarId: "avatar_123",
      ownerId: ownerId,
      fidelityScore: 0.95,
      lastUpdated: DateTime.now(),
      voiceId: "voice_123",
      faceId: "face_123",
      behaviorProfileId: "behavior_123",
      status: "sleeping",
    );
  }
}
