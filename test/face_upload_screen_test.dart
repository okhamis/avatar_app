import 'package:ai_digital_twin/models/user_model.dart';
import 'package:ai_digital_twin/providers/auth_provider.dart';
import 'package:ai_digital_twin/providers/avatar_provider.dart';
import 'package:ai_digital_twin/routes/route_names.dart';
import 'package:ai_digital_twin/screens/onboarding/face_upload_screen.dart';
import 'package:ai_digital_twin/models/avatar_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class _TestAuthNotifier extends AuthNotifier {
  bool updated = false;

  @override
  UserModel? build() {
    return UserModel(uid: 'u1', email: 'test@example.com', fullName: 'Test User');
  }

  @override
  Future<void> updateTrainingFlags({
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {
    updated = hasFaceTrained == true;
  }
}

class _TestAvatarNotifier extends AvatarNotifier {
  bool saved = false;
  List<String> savedPaths = const [];

  @override
  AvatarModel? build() {
    return null;
  }

  @override
  Future<void> saveFaceDraft({
    required String ownerId,
    required List<String> imagePaths,
  }) async {
    saved = true;
    savedPaths = imagePaths;
  }
}

void main() {
  testWidgets('face upload continue saves photos and navigates', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final initialPhotos = List.generate(5, (i) => XFile('mock_photo_$i.jpg'));

    final router = GoRouter(
      initialLocation: '/face',
      routes: [
        GoRoute(
          path: '/face',
          name: RouteNames.faceUpload,
          builder: (context, state) => FaceUploadScreen(
            initialPhotos: initialPhotos,
            renderPhotoThumbnails: false,
          ),
        ),
        GoRoute(
          path: '/voice',
          name: RouteNames.voiceRecord,
          builder: (context, state) => const Scaffold(body: Text('Voice Screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          avatarProvider.overrideWith(_TestAvatarNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ready to proceed to the next step'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    for (var i = 0; i < 20 && find.text('Voice Screen').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Voice Screen'), findsOneWidget);

    final auth = tester.container().read(authProvider.notifier) as _TestAuthNotifier;
    final avatar = tester.container().read(avatarProvider.notifier) as _TestAvatarNotifier;
    expect(auth.updated, isTrue);
    expect(avatar.saved, isTrue);
    expect(avatar.savedPaths.length, 5);
  });
}
