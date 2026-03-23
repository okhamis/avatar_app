import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar_model.dart';
import '../services/behavioral_llm.dart';
import '../services/claude_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/gemini_service.dart';
import '../services/heygen_service.dart';

final heygenProvider = Provider((ref) => HeyGenService());
final elevenlabsProvider = Provider((ref) => ElevenLabsService());

/// Use **Gemini** or **Claude** for live avatar replies. Set in `.env`:
/// `BEHAVIOR_LLM=gemini` (default) or `BEHAVIOR_LLM=claude`.
final behavioralLlmProvider = Provider<BehavioralLlm>((ref) {
  final mode = dotenv.env['BEHAVIOR_LLM']?.toLowerCase().trim() ?? 'gemini';
  if (mode == 'claude') {
    return ClaudeService();
  }
  return GeminiService();
});

final avatarProvider = NotifierProvider<AvatarNotifier, AvatarModel?>(AvatarNotifier.new);

class AvatarNotifier extends Notifier<AvatarModel?> {
  late final HeyGenService _heyGen;
  late final ElevenLabsService _elevenLabs;
  late final BehavioralLlm _behavioralLlm;

  @override
  AvatarModel? build() {
    _heyGen = ref.watch(heygenProvider);
    _elevenLabs = ref.watch(elevenlabsProvider);
    _behavioralLlm = ref.watch(behavioralLlmProvider);
    return null;
  }

  Future<void> createAvatar(String ownerId) async {
    await _behavioralLlm.trainBehavior({});
    await _elevenLabs.cloneVoice('mock_recording_path.m4a');
    await _heyGen.trainFaceModel(const <String>[]);
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
