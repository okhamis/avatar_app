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
import '../services/did_service.dart';
import '../core/providers/service_providers.dart';
import '../core/utils/app_logger.dart';

final elevenlabsProvider = Provider((ref) => ElevenLabsService());

/// Use **Gemini** or **Claude** for live avatar replies. Set in `.env`:
/// `BEHAVIOR_LLM=gemini` (default) or `BEHAVIOR_LLM=claude`.
///
/// When [AppConfig.useBackendBehaviorLlm] is true, replies go through the `behavioralChat` Cloud Function (Gemini on the server).
final behavioralLlmProvider = Provider<BehavioralLlm>((ref) {
  if (AppConfig.useBackendBehaviorLlm) {
    if (AppConfig.behaviorLlm == 'claude' && kDebugMode) {
      AppLogger.avatar.w('USE_BACKEND_LLM=true: server uses Gemini; BEHAVIOR_LLM=claude is ignored for live chat');
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
  late final ElevenLabsService _elevenLabs;
  late final BehavioralLlm _behavioralLlm;
  late final FirebaseService _firebaseService;

  @override
  AvatarModel? build() {
    _elevenLabs = ref.watch(elevenlabsProvider);
    _behavioralLlm = ref.watch(behavioralLlmProvider);
    _firebaseService = ref.watch(firebaseServiceProvider);
    return null;
  }

  Future<void> loadAvatar(String ownerId) async {
    AppLogger.avatar.d('loadAvatar ownerId=$ownerId');
    try {
      state = await _firebaseService.getAvatarProfile(ownerId);
      AppLogger.avatar.i('loadAvatar result: status=${state?.status} faceId=${state?.faceId} voiceId=${state?.voiceId}');
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  Future<void> saveFaceDraft({
    required String ownerId,
    required List<String> imagePaths,
  }) async {
    AppLogger.avatar.d('saveFaceDraft ownerId=$ownerId imageCount=${imagePaths.length}');
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

    // Upload the first face photo to D-ID /images so streaming sessions
    // can use the returned URL as source_url.
    String? didImageUrl;
    if (imagePaths.isNotEmpty) {
      final firstPath = imagePaths.first;
      if (!firstPath.startsWith('http')) {
        try {
          final didService = DidService();
          didImageUrl = await didService.uploadImage(firstPath);
          AppLogger.avatar.i('saveFaceDraft — D-ID image uploaded url=$didImageUrl');
        } catch (e) {
          AppLogger.avatar.w('saveFaceDraft — D-ID image upload failed (non-fatal)', error: e);
        }
      } else {
        didImageUrl = firstPath;
        AppLogger.avatar.d('saveFaceDraft — using existing URL as faceId: $didImageUrl');
      }
    }

    final withFace = (state ?? next).copyWith(
      faceId: didImageUrl ?? next.faceId,
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

  /// Returns the cloned ElevenLabs voice_id on success, or empty string on failure.
  Future<String> saveVoiceDraft({
    required String ownerId,
    required String samplePath,
  }) async {
    AppLogger.avatar.d('saveVoiceDraft ownerId=$ownerId samplePath=$samplePath');
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

    String clonedVoiceId = '';
    if (samplePath.isNotEmpty) {
      try {
        AppLogger.avatar.d('saveVoiceDraft — calling ElevenLabs cloneVoice...');
        clonedVoiceId = await _elevenLabs.cloneVoice(samplePath, name: 'Presnt-$ownerId');
        AppLogger.avatar.i('saveVoiceDraft — ElevenLabs cloned voice_id=$clonedVoiceId');
      } catch (e) {
        AppLogger.avatar.w('saveVoiceDraft — ElevenLabs voice clone failed (non-fatal)', error: e);
      }
    }

    final withVoice = (state ?? next).copyWith(
      voiceId: clonedVoiceId.isNotEmpty ? clonedVoiceId : next.voiceId,
    );
    state = withVoice;

    try {
      AppLogger.avatar.d('saveVoiceDraft — saving avatar profile to Firebase...');
      await _firebaseService.saveAvatarProfile(withVoice);
      AppLogger.avatar.d('saveVoiceDraft — updating training flags...');
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasVoiceCloned: samplePath.isNotEmpty);
      AppLogger.avatar.d('saveVoiceDraft — Firebase writes done');
    } catch (e) {
      AppLogger.avatar.w('saveVoiceDraft — Firebase error', error: e);
      if (_isNoAppInDebug(e)) return clonedVoiceId;
      rethrow;
    }
    return clonedVoiceId;
  }

  /// Persists a known ElevenLabs [voiceId] without cloning — useful for test profiles.
  Future<void> savePresetVoiceId({
    required String ownerId,
    required String voiceId,
  }) async {
    AppLogger.avatar.d('savePresetVoiceId ownerId=$ownerId voiceId=$voiceId');
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    final withVoice = current.copyWith(
      voiceId: voiceId,
      hasVoiceSample: true,
      lastUpdated: now,
    );
    state = withVoice;
    try {
      await _firebaseService.saveAvatarProfile(withVoice);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasVoiceCloned: true);
      AppLogger.avatar.i('savePresetVoiceId OK ownerId=$ownerId voiceId=$voiceId');
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  Future<void> trainBehaviorProfile({
    required String ownerId,
    required Map<String, String> answers,
  }) async {
    AppLogger.avatar.d('trainBehaviorProfile ownerId=$ownerId answersCount=${answers.length}');
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
      AppLogger.avatar.i('trainBehaviorProfile complete behaviorId=$behaviorId fidelity=${next.fidelityScore}');
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
      AppLogger.avatar.e('trainBehaviorProfile failed — status set to error');
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
    AppLogger.avatar.i('finalizeAvatar ownerId=$ownerId faceImages=${faceImagePaths.length}');
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    state = current.copyWith(status: AvatarStatus.training, lastUpdated: now);

    try {
      String faceId = '';
      if (faceImagePaths.isNotEmpty) {
        final firstPath = faceImagePaths.first;
        if (!firstPath.startsWith('http')) {
          try {
            faceId = await DidService().uploadImage(firstPath) ?? '';
            AppLogger.avatar.i('finalizeAvatar — D-ID image uploaded faceId=$faceId');
          } catch (e) {
            AppLogger.avatar.w('finalizeAvatar — D-ID upload failed (non-fatal)', error: e);
          }
        } else {
          faceId = firstPath;
        }
      }
      try {
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasFaceTrained: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }

      final voiceId = await _elevenLabs.cloneVoice(voiceSamplePath);
      AppLogger.avatar.i('finalizeAvatar — voice cloned voiceId=$voiceId');
      try {
        await _firebaseService.updateUserTrainingFlags(uid: ownerId, hasVoiceCloned: true);
      } catch (e) {
        if (!_isNoAppInDebug(e)) rethrow;
      }

      final behaviorId = await _behavioralLlm.trainBehavior(behavioralAnswers);
      AppLogger.avatar.i('finalizeAvatar — behavior trained behaviorId=$behaviorId');
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
      AppLogger.avatar.i('finalizeAvatar — status=${next.status} fidelity=${next.fidelityScore}');
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
      AppLogger.avatar.e('finalizeAvatar failed — status set to error');
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
    AppLogger.avatar.i('setAvatarLive ownerId=$ownerId isLive=$isLive');
    final now = DateTime.now();
    final current = state ?? _newDraft(ownerId, now);
    final next = current.copyWith(
      status: isLive ? AvatarStatus.live : AvatarStatus.ready,
      lastUpdated: now,
    );
    state = next;
    AppLogger.avatar.i('setAvatarLive — status changed to ${next.status}');
    try {
      await _firebaseService.saveAvatarProfile(next);
      await _firebaseService.updateUserTrainingFlags(uid: ownerId, isLive: isLive);
    } catch (e) {
      if (_isNoAppInDebug(e)) return;
      rethrow;
    }
  }

  AvatarModel _newDraft(String ownerId, DateTime now) {
    AppLogger.avatar.d('_newDraft ownerId=$ownerId');
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
    if (kDebugMode && e is FirebaseException && (e.code == 'no-app' || e.code == 'unavailable')) {
      AppLogger.avatar.d('_isNoAppInDebug — skipping Firebase avatar persistence (${e.code})');
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
      AppLogger.avatar.d('_stablePreviewPath — copied to $destPath');
      return destPath;
    } catch (e) {
      AppLogger.avatar.w('_stablePreviewPath — copy to documents failed', error: e);
      return source;
    }
  }

  Future<void> _tryUploadPreviewToCloud(AvatarModel model, String ownerId) async {
    final path = model.previewImagePath;
    if (path == null || path.isEmpty || path.startsWith('http')) return;
    final file = File(path);
    if (!await file.exists()) return;
    AppLogger.avatar.d('_tryUploadPreviewToCloud ownerId=$ownerId path=$path');
    try {
      final url = await _firebaseService.uploadAvatarPreviewImage(ownerId: ownerId, file: file);
      if (url == null || url.isEmpty) return;
      final synced = model.copyWith(previewImagePath: url, lastUpdated: DateTime.now());
      state = synced;
      await _firebaseService.saveAvatarProfile(synced);
      AppLogger.avatar.i('_tryUploadPreviewToCloud OK url=$url');
    } catch (e) {
      AppLogger.avatar.w('_tryUploadPreviewToCloud — cloud sync failed', error: e);
    }
  }
}
