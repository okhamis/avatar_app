import 'dart:io';

import 'package:ai_digital_twin/models/avatar_model.dart';
import 'package:ai_digital_twin/providers/avatar_provider.dart';
import 'package:ai_digital_twin/services/behavioral_llm.dart';
import 'package:ai_digital_twin/services/elevenlabs_service.dart';
import 'package:ai_digital_twin/services/firebase_service.dart';
import 'package:ai_digital_twin/services/heygen_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBehavioralLlm implements BehavioralLlm {
  @override
  Future<String> generateBehavioralResponse(String prompt) async => 'ok';

  @override
  Future<String> trainBehavior(Map<String, String> answers) async => 'behavior_1';
}

class _FakeHeyGenService extends HeyGenService {
  @override
  Future<String> trainFaceModel(List<String> imagePaths) async => 'face_1';
}

class _FakeElevenLabsService extends ElevenLabsService {
  @override
  Future<String> cloneVoice(String audioFilePath) async => 'voice_1';
}

class _FakeFirebaseService extends FirebaseService {
  AvatarModel? savedAvatar;

  @override
  Future<AvatarModel?> getAvatarProfile(String ownerId) async => savedAvatar;

  @override
  Future<void> saveAvatarProfile(AvatarModel avatar) async {
    savedAvatar = avatar;
  }

  @override
  Future<void> updateUserTrainingFlags({
    required String uid,
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {}

  @override
  Future<String?> uploadAvatarPreviewImage({
    required String ownerId,
    required File file,
  }) async =>
      null;
}

void main() {
  test('trainBehaviorProfile includes behavior in fidelity score', () async {
    final fakeFirebase = _FakeFirebaseService();
    final container = ProviderContainer(
      overrides: [
        behavioralLlmProvider.overrideWithValue(_FakeBehavioralLlm()),
        heygenProvider.overrideWithValue(_FakeHeyGenService()),
        elevenlabsProvider.overrideWithValue(_FakeElevenLabsService()),
        avatarFirebaseServiceProvider.overrideWithValue(fakeFirebase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(avatarProvider.notifier);
    await notifier.saveFaceDraft(ownerId: 'u1', imagePaths: List.generate(5, (i) => 'img_$i'));
    await notifier.saveVoiceDraft(ownerId: 'u1', samplePath: 'voice.m4a');
    await notifier.trainBehaviorProfile(ownerId: 'u1', answers: const {'q1': 'answer'});

    final avatar = container.read(avatarProvider);
    expect(avatar, isNotNull);
    expect(avatar!.behaviorProfileId, isNotEmpty);
    expect(avatar.fidelityScore, 0.99);
    expect(avatar.status, AvatarStatus.ready);
  });

  test('finalizeAvatar computes fidelity with trained behavior', () async {
    final fakeFirebase = _FakeFirebaseService();
    final container = ProviderContainer(
      overrides: [
        behavioralLlmProvider.overrideWithValue(_FakeBehavioralLlm()),
        heygenProvider.overrideWithValue(_FakeHeyGenService()),
        elevenlabsProvider.overrideWithValue(_FakeElevenLabsService()),
        avatarFirebaseServiceProvider.overrideWithValue(fakeFirebase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(avatarProvider.notifier);
    await notifier.finalizeAvatar(
      ownerId: 'u1',
      faceImagePaths: List.generate(5, (i) => 'img_$i'),
      voiceSamplePath: 'voice.m4a',
      behavioralAnswers: const {'q1': 'answer'},
    );

    final avatar = container.read(avatarProvider);
    expect(avatar, isNotNull);
    expect(avatar!.behaviorProfileId, isNotEmpty);
    expect(avatar.fidelityScore, 0.99);
    expect(avatar.status, AvatarStatus.ready);
  });
}
