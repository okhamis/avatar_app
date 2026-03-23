import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/avatar_model.dart';
import '../services/behavioral_llm.dart';
import '../services/claude_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/heygen_service.dart';

final heygenProvider = Provider((ref) => HeyGenService());
final elevenlabsProvider = Provider((ref) => ElevenLabsService());
final avatarFirebaseServiceProvider = Provider((ref) => FirebaseService());

/// Use **Gemini** or **Claude** for live avatar replies. Set in `.env`:
/// `BEHAVIOR_LLM=gemini` (default) or `BEHAVIOR_LLM=claude`.
final behavioralLlmProvider = Provider<BehavioralLlm>((ref) {
  String mode = 'gemini';
  try {
    mode = dotenv.env['BEHAVIOR_LLM']?.toLowerCase().trim() ?? 'gemini';
  } catch (_) {
    mode = 'gemini';
  }
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
  late final FirebaseService _firebaseService;

  @override
  AvatarModel? build() {
    _heyGen = ref.watch(heygenProvider);
    _elevenLabs = ref.watch(elevenlabsProvider);
    _behavioralLlm = ref.watch(behavioralLlmProvider);
    _firebaseService = ref.watch(avatarFirebaseServiceProvider);
    return null;
  }

  Future<void> loadAvatar(String ownerId) async {
    try {
      state = await _firebaseService.getAvatarProfile(ownerId);
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  Future<void> saveFaceDraft({
    required String ownerId,
    required List<String> imagePaths,
  }) async {
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    final next = current.copyWith(
      status: AvatarStatus.training,
      previewImagePath: imagePaths.isNotEmpty ? imagePaths.first : current.previewImagePath,
      faceSampleCount: imagePaths.length,
      lastUpdated: now,
      lastErrorCode: null,
      lastErrorMessage: null,
    );
    state = next;
    try {
      await _firebaseService.saveAvatarProfile(next);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasFaceTrained: imagePaths.isNotEmpty);
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  Future<void> saveVoiceDraft({
    required String ownerId,
    required String samplePath,
  }) async {
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    final next = current.copyWith(
      status: AvatarStatus.training,
      hasVoiceSample: samplePath.isNotEmpty,
      lastUpdated: now,
      lastErrorCode: null,
      lastErrorMessage: null,
    );
    state = next;
    try {
      await _firebaseService.saveAvatarProfile(next);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasVoiceCloned: samplePath.isNotEmpty);
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  Future<void> trainBehaviorProfile({
    required String ownerId,
    required Map<String, String> answers,
  }) async {
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    state = current.copyWith(status: AvatarStatus.training, lastUpdated: now, lastErrorCode: null, lastErrorMessage: null);
    try {
      final behaviorId = await _behavioralLlm.trainBehavior(answers);
      final withBehavior = (state ?? current).copyWith(
        behaviorProfileId: behaviorId,
      );
      final next = withBehavior.copyWith(
        status: AvatarStatus.ready,
        fidelityScore: _computeFidelity(withBehavior),
        lastUpdated: DateTime.now(),
      );
      state = next;
      try {
        await _firebaseService.saveAvatarProfile(next);
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasBehaviorTrained: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }
    } catch (_) {
      final failed = (state ?? current).copyWith(
        status: AvatarStatus.error,
        lastUpdated: DateTime.now(),
        lastErrorCode: 'behavior-training-failed',
        lastErrorMessage: 'Behavior training failed. Please retry.',
      );
      state = failed;
      try {
        await _firebaseService.saveAvatarProfile(failed);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }
      rethrow;
    }
  }

  Future<void> finalizeAvatar({
    required String ownerId,
    required List<String> faceImagePaths,
    required String voiceSamplePath,
    required Map<String, String> behavioralAnswers,
  }) async {
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    state = current.copyWith(status: AvatarStatus.training, lastUpdated: now);

    try {
      final faceId = await _heyGen.trainFaceModel(faceImagePaths);
      try {
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasFaceTrained: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }

      final voiceId = await _elevenLabs.cloneVoice(voiceSamplePath);
      try {
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasVoiceCloned: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }

      final behaviorId = await _behavioralLlm.trainBehavior(behavioralAnswers);
      try {
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasBehaviorTrained: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }

      final withTrainingData = (state ?? current).copyWith(
        faceId: faceId,
        voiceId: voiceId,
        behaviorProfileId: behaviorId,
        faceSampleCount: faceImagePaths.length,
        hasVoiceSample: voiceSamplePath.isNotEmpty,
        previewImagePath: faceImagePaths.isNotEmpty ? faceImagePaths.first : null,
      );
      final next = withTrainingData.copyWith(
        fidelityScore: _computeFidelity(withTrainingData),
        status: AvatarStatus.ready,
        lastUpdated: DateTime.now(),
        lastErrorCode: null,
        lastErrorMessage: null,
      );
      state = next;
      try {
        await _firebaseService.saveAvatarProfile(next);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }
    } catch (_) {
      final failed = (state ?? current).copyWith(
        status: AvatarStatus.error,
        lastUpdated: DateTime.now(),
        lastErrorCode: 'avatar-finalize-failed',
        lastErrorMessage: 'Could not complete avatar training. Please retry.',
      );
      state = failed;
      try {
        await _firebaseService.saveAvatarProfile(failed);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }
      rethrow;
    }
  }

  Future<void> setAvatarLive({
    required String ownerId,
    required bool isLive,
  }) async {
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    final next = current.copyWith(
      status: isLive ? AvatarStatus.live : AvatarStatus.ready,
      lastUpdated: now,
    );
    state = next;
    try {
      await _firebaseService.saveAvatarProfile(next);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, isLive: isLive);
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  AvatarModel _newDraft(String ownerId, DateTime now) {
    state = AvatarModel(
      avatarId: ownerId,
      ownerId: ownerId,
      fidelityScore: 0.0,
      createdAt: now,
      lastUpdated: now,
      voiceId: "",
      faceId: "",
      behaviorProfileId: "",
      status: AvatarStatus.draft,
    );
    return state!;
  }

  double _computeFidelity(AvatarModel avatar) {
    var score = 0.35;
    if (avatar.faceSampleCount >= 5) score += 0.25;
    if (avatar.hasVoiceSample) score += 0.2;
    if (avatar.behaviorProfileId.isNotEmpty) score += 0.2;
    return score.clamp(0.0, 0.99);
  }

  bool _isNoAppInDebug(Object e) {
    if (kDebugMode && e is FirebaseException && e.code == 'no-app') {
      debugPrint('Skipping Firebase avatar persistence in debug mode.');
      return true;
    }
    return false;
  }
}
