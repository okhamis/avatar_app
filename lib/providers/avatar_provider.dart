import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import '../models/avatar_model.dart';
import '../services/behavioral_llm.dart';
import '../services/claude_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/firebase_service.dart';
import '../services/backend_behavioral_llm_service.dart';
import '../services/gemini_service.dart';
import '../services/heygen_service.dart';
import '../core/providers/service_providers.dart';

final heygenProvider = Provider((ref) => HeyGenService());
final elevenlabsProvider = Provider((ref) => ElevenLabsService());

/// Use **Gemini** or **Claude** for live avatar replies. Set in `.env`:
/// `BEHAVIOR_LLM=gemini` (default) or `BEHAVIOR_LLM=claude`.
///
/// When [AppConfig.useBackendBehaviorLlm] is true, replies go through the `behavioralChat` Cloud Function (Gemini on the server).
final behavioralLlmProvider = Provider<BehavioralLlm>((ref) {
  if (AppConfig.useBackendBehaviorLlm) {
    if (AppConfig.behaviorLlm == 'claude' && kDebugMode) {
      debugPrint('USE_BACKEND_LLM=true: server uses Gemini; BEHAVIOR_LLM=claude is ignored for live chat.');
    }
    return BackendBehavioralLlmService();
  }
  String mode = 'gemini';
  try {
    mode = AppConfig.behaviorLlm;
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
    _firebaseService = ref.watch(firebaseServiceProvider);
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
    String? previewPath = current.previewImagePath;
    if (imagePaths.isNotEmpty) {
      previewPath = await _stablePreviewPath(imagePaths.first, ownerId);
    }
    final next = current.copyWith(
      status: AvatarStatus.training,
      previewImagePath: previewPath,
      faceSampleCount: imagePaths.length,
      lastUpdated: now,
      lastErrorCode: null,
      lastErrorMessage: null,
    );
    state = next;

    // Upload photos to HeyGen and create a Photo Avatar (non-blocking).
    // The resulting group_id is stored as faceId so streaming sessions
    // render the user's own face.
    String? heygenGroupId;
    try {
      heygenGroupId = await _heyGen.createPhotoAvatar(imagePaths, name: 'Presnt-$ownerId');
      debugPrint('[avatar] HeyGen photo avatar group_id=$heygenGroupId');
    } catch (e) {
      debugPrint('[avatar] HeyGen photo avatar creation failed (non-fatal): $e');
    }

    final withFace = (state ?? next).copyWith(
      faceId: heygenGroupId ?? next.faceId,
    );
    state = withFace;

    try {
      await _firebaseService.saveAvatarProfile(withFace);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasFaceTrained: imagePaths.isNotEmpty);
      await _tryUploadPreviewToCloud(withFace, ownerId);
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

    // Clone the voice via ElevenLabs (non-blocking on failure).
    String clonedVoiceId = '';
    if (samplePath.isNotEmpty) {
      try {
        clonedVoiceId = await _elevenLabs.cloneVoice(samplePath, name: 'Presnt-$ownerId');
        debugPrint('[avatar] ElevenLabs cloned voice_id=$clonedVoiceId');
      } catch (e) {
        debugPrint('[avatar] ElevenLabs voice clone failed (non-fatal): $e');
      }
    }

    final withVoice = (state ?? next).copyWith(
      voiceId: clonedVoiceId.isNotEmpty ? clonedVoiceId : next.voiceId,
    );
    state = withVoice;

    try {
      await _firebaseService.saveAvatarProfile(withVoice);
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
      final faceId = await _heyGen.createPhotoAvatar(faceImagePaths, name: 'Presnt-$ownerId') ?? '';
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

      String? resolvedPreview;
      if (faceImagePaths.isNotEmpty) {
        resolvedPreview = await _stablePreviewPath(faceImagePaths.first, ownerId);
      }

      final withTrainingData = (state ?? current).copyWith(
        faceId: faceId,
        voiceId: voiceId,
        behaviorProfileId: behaviorId,
        faceSampleCount: faceImagePaths.length,
        hasVoiceSample: voiceSamplePath.isNotEmpty,
        previewImagePath: resolvedPreview,
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
        await _tryUploadPreviewToCloud(next, ownerId);
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

  /// Copies the picked file into app documents so tmp/cache paths are not reused incorrectly after restart.
  Future<String?> _stablePreviewPath(String source, String ownerId) async {
    if (source.startsWith('http')) return source;
    final src = File(source);
    if (!await src.exists()) return source;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/avatar_preview_$ownerId.jpg';
      await src.copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('[avatar] preview copy to documents failed: $e');
      return source;
    }
  }

  Future<void> _tryUploadPreviewToCloud(AvatarModel model, String ownerId) async {
    final path = model.previewImagePath;
    if (path == null || path.isEmpty || path.startsWith('http')) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final url = await _firebaseService.uploadAvatarPreviewImage(ownerId: ownerId, file: file);
      if (url == null || url.isEmpty) return;
      final synced = model.copyWith(previewImagePath: url, lastUpdated: DateTime.now());
      state = synced;
      await _firebaseService.saveAvatarProfile(synced);
    } catch (e) {
      debugPrint('[avatar] preview cloud sync failed: $e');
    }
  }
}
