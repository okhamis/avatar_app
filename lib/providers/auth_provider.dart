import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../core/providers/service_providers.dart';
import '../core/utils/app_logger.dart';
import '../config/test_profile_config.dart';
import 'avatar_provider.dart';
import 'streaming_settings_provider.dart';

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthLinkRequiredException implements Exception {
  AuthLinkRequiredException({
    required this.email,
    required this.signInMethods,
    required this.pendingProviderId,
  });

  final String email;
  final List<String> signInMethods;
  final String pendingProviderId;
}

class AuthNotifier extends Notifier<UserModel?> {
  FirebaseService get _firebaseService => ref.read(firebaseServiceProvider);
  AuthCredential? _pendingOAuthCredential;
  String? _pendingProviderId;
  String? _pendingEmail;

  @override
  UserModel? build() {
    return null;
  }

  Future<void> restoreSessionUser() async {
    AppLogger.auth.d('restoreSessionUser — checking FirebaseAuth.currentUser');
    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') {
        AppLogger.auth.w('restoreSessionUser — Firebase not configured (no-app)');
        state = null;
        return;
      }
      rethrow;
    }
    if (firebaseUser == null) {
      AppLogger.auth.d('restoreSessionUser — no current user');
      state = null;
      return;
    }
    AppLogger.auth.d('restoreSessionUser — found user uid=${firebaseUser.uid}');
    try {
      final userProfile = await _firebaseService.getUserProfile(firebaseUser.uid);
      await _updateStateWithTestCheck(userProfile);
      AppLogger.auth.i('restoreSessionUser — session restored uid=${firebaseUser.uid}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        final newUser = UserModel(uid: firebaseUser.uid, email: firebaseUser.email ?? '', fullName: firebaseUser.displayName ?? 'User');
        await _firebaseService.saveUserProfile(newUser);
        await _updateStateWithTestCheck(newUser);
        AppLogger.auth.i('restoreSessionUser — new user created uid=${firebaseUser.uid}');
        return;
      }
      // Firestore unavailable — fall back to basic user from Firebase Auth
      AppLogger.auth.w('restoreSessionUser — Firestore unavailable (${e.code}), using Firebase Auth data');
      final fallback = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        fullName: firebaseUser.displayName ?? 'User',
      );
      await _updateStateWithTestCheck(fallback);
    }
  }

  Future<void> login(String email, String password) async {
    AppLogger.auth.d('login email=$email');
    try {
      final credential = await _firebaseService.signInWithEmail(email, password);
      if (credential.user?.uid != null) {
        try {
          final user = await _firebaseService.getUserProfile(credential.user!.uid);
          await _updateStateWithTestCheck(user);
        } catch (profileErr) {
          AppLogger.auth.w('login — Firestore profile fetch failed, using basic user', error: profileErr);
          state = UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? email,
            fullName: credential.user!.displayName ?? 'User',
          );
        }
        AppLogger.auth.i('login OK uid=${credential.user?.uid}');
        return;
      }
      throw Exception('Login failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      AppLogger.auth.w('login FirebaseAuthException code=${e.code}', error: e.message);
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      AppLogger.auth.e('login FirebaseException code=${e.code}', error: e.message);
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      AppLogger.auth.e('login unexpected error [${e.runtimeType}]', error: e);
      throw Exception('Login failed. Please try again.');
    }
  }

  Future<void> loginWithGoogle() async {
    AppLogger.auth.d('loginWithGoogle');
    try {
      final credential = await _firebaseService.signInWithGoogle();
      await _syncAuthenticatedUser(credential, fallbackEmail: credential.user?.email ?? '');
      AppLogger.auth.i('loginWithGoogle OK uid=${credential.user?.uid}');
    } on FirebaseAuthException catch (e) {
      AppLogger.auth.w('loginWithGoogle FirebaseAuthException code=${e.code}', error: e.message);
      if (e.code == 'account-exists-with-different-credential' && e.credential != null && (e.email?.isNotEmpty ?? false)) {
        _pendingOAuthCredential = e.credential;
        _pendingProviderId = GoogleAuthProvider.PROVIDER_ID;
        _pendingEmail = e.email;
        throw AuthLinkRequiredException(
          email: e.email!,
          signInMethods: const ['password'],
          pendingProviderId: GoogleAuthProvider.PROVIDER_ID,
        );
      }
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      AppLogger.auth.e('loginWithGoogle FirebaseException code=${e.code}', error: e.message);
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      AppLogger.auth.e('loginWithGoogle unexpected error [${e.runtimeType}]', error: e);
      if (e.toString().contains('GIDClientID')) {
        throw Exception(
          'Google Sign-In is not configured for macOS. Add CLIENT_ID/REVERSED_CLIENT_ID to macOS GoogleService-Info.plist and set GIDClientID in macOS Info.plist.',
        );
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  Future<void> loginWithFacebook() async {
    AppLogger.auth.d('loginWithFacebook');
    try {
      final credential = await _firebaseService.signInWithFacebook();
      await _syncAuthenticatedUser(credential, fallbackEmail: credential.user?.email ?? '');
      AppLogger.auth.i('loginWithFacebook OK uid=${credential.user?.uid}');
    } on FirebaseAuthException catch (e) {
      AppLogger.auth.w('loginWithFacebook FirebaseAuthException code=${e.code}', error: e.message);
      if (e.code == 'account-exists-with-different-credential' && e.credential != null && (e.email?.isNotEmpty ?? false)) {
        _pendingOAuthCredential = e.credential;
        _pendingProviderId = FacebookAuthProvider.PROVIDER_ID;
        _pendingEmail = e.email;
        throw AuthLinkRequiredException(
          email: e.email!,
          signInMethods: const ['password'],
          pendingProviderId: FacebookAuthProvider.PROVIDER_ID,
        );
      }
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      AppLogger.auth.e('loginWithFacebook FirebaseException code=${e.code}', error: e.message);
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      AppLogger.auth.e('loginWithFacebook unexpected error [${e.runtimeType}]', error: e);
      throw Exception('Facebook sign-in failed. Please try again.');
    }
  }

  Future<void> resolvePendingLinkWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final pending = _pendingOAuthCredential;
    if (pending == null || _pendingEmail == null || _pendingProviderId == null) {
      throw Exception('No pending provider link request.');
    }
    if (_pendingEmail != email) {
      throw Exception('Please use the same email requested for linking.');
    }

    AppLogger.auth.d('resolvePendingLinkWithEmailPassword email=$email provider=$_pendingProviderId');
    final emailCredential = await _firebaseService.signInWithEmail(email, password);
    try {
      final linkedCredential = await _firebaseService.linkCurrentUserWithCredential(pending);
      await _syncAuthenticatedUser(
        linkedCredential,
        fallbackEmail: linkedCredential.user?.email ?? emailCredential.user?.email ?? email,
      );
      AppLogger.auth.i('resolvePendingLink OK uid=${linkedCredential.user?.uid}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked' || e.code == 'credential-already-in-use') {
        final signedIn = await _firebaseService.signInWithCredential(pending);
        await _syncAuthenticatedUser(signedIn, fallbackEmail: signedIn.user?.email ?? email);
      } else {
        rethrow;
      }
    } finally {
      _pendingOAuthCredential = null;
      _pendingProviderId = null;
      _pendingEmail = null;
    }
  }

  Future<void> createAccount(String fullName, String email, String password) async {
    AppLogger.auth.d('createAccount email=$email');
    try {
      AppLogger.auth.d('createAccount — calling createUserWithEmail...');
      final credential = await _firebaseService.createUserWithEmail(email, password);
      AppLogger.auth.d('createAccount — createUserWithEmail returned uid=${credential.user?.uid}');
      final uid = credential.user?.uid;

      if (uid == null) {
        AppLogger.auth.e('createAccount — uid is null after createUserWithEmail');
        throw Exception('Unable to create account. Please try again.');
      }

      final user = UserModel(uid: uid, email: email, fullName: fullName);
      try {
        await _firebaseService.saveUserProfile(user);
        AppLogger.auth.d('createAccount — saveUserProfile succeeded');
      } catch (firestoreErr) {
        AppLogger.auth.w('createAccount — Firestore save failed (continuing)', error: firestoreErr);
      }
      await _updateStateWithTestCheck(user);
      AppLogger.auth.i('createAccount SUCCESS uid=$uid');
    } on FirebaseAuthException catch (e) {
      AppLogger.auth.w('createAccount FirebaseAuthException code=${e.code}', error: e.message);
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      AppLogger.auth.e('createAccount FirebaseException code=${e.code}', error: e.message);
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      AppLogger.auth.e('createAccount unexpected error [${e.runtimeType}]', error: e);
      throw Exception('Account creation failed. Please try again.');
    }
  }

  Future<void> logout() async {
    AppLogger.auth.i('logout initiated uid=${state?.uid}');
    await _firebaseService.signOut();
    state = null;
    AppLogger.auth.i('logout complete');
  }

  Future<void> updateTrainingFlags({
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {
    final user = state;
    if (user == null) return;
    AppLogger.auth.d('updateTrainingFlags uid=${user.uid} face=$hasFaceTrained voice=$hasVoiceCloned behavior=$hasBehaviorTrained isLive=$isLive');
    final updated = user.copyWith(
      hasFaceTrained: hasFaceTrained ?? user.hasFaceTrained,
      hasVoiceCloned: hasVoiceCloned ?? user.hasVoiceCloned,
      hasBehaviorTrained: hasBehaviorTrained ?? user.hasBehaviorTrained,
      isLive: isLive ?? user.isLive,
    );
    state = updated;
    try {
      await _firebaseService.saveUserProfile(updated);
    } on FirebaseException catch (e) {
      if (kDebugMode && e.code == 'no-app') {
        AppLogger.auth.d('updateTrainingFlags — skipping Firebase save in debug no-app mode');
        return;
      }
      rethrow;
    }
  }

  Future<void> _syncAuthenticatedUser(
    UserCredential credential, {
    required String fallbackEmail,
  }) async {
    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Login failed. Please try again.');
    }
    AppLogger.auth.d('_syncAuthenticatedUser uid=$uid');
    try {
      final existing = await _firebaseService.getUserProfile(uid);
      state = existing;
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }

    final user = UserModel(
      uid: uid,
      email: credential.user?.email ?? fallbackEmail,
      fullName: credential.user?.displayName ?? 'User',
    );
    await _firebaseService.saveUserProfile(user);
    await _updateStateWithTestCheck(user);
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'This email is already used with another sign-in method. Sign in with that method first.';
      case 'popup-closed-by-user':
      case 'canceled':
      case 'web-context-cancelled':
        return 'Sign-in was cancelled.';
      case 'internal-error':
        return 'Authentication backend rejected the request. Verify Firebase Authentication is enabled for Email/Password and try again.';
      default:
        return e.message ?? 'Account creation failed. Please try again.';
    }
  }

  String _friendlyFirebaseMessage(FirebaseException e) {
    if (e.code == 'no-app') {
      return 'Firebase is not configured yet. Please run FlutterFire setup for this app first.';
    }
    return e.message ?? 'Firebase error. Please try again.';
  }

  Future<void> _updateStateWithTestCheck(UserModel user) async {
    final useTestProfile = ref.read(testProfileEnabledProvider);
    var targetUser = user;
    if (useTestProfile && !targetUser.isLive && (!targetUser.hasFaceTrained || !targetUser.hasVoiceCloned || !targetUser.hasBehaviorTrained)) {
      AppLogger.auth.i('_updateStateWithTestCheck — auto-injecting test profile uid=${user.uid}');

      // Always set training flags first (unconditionally), regardless of upload success.
      targetUser = targetUser.copyWith(
        hasFaceTrained: true,
        hasVoiceCloned: true,
        hasBehaviorTrained: true,
      );
      try {
        await _firebaseService.saveUserProfile(targetUser);
      } catch (e) {
        AppLogger.auth.w('_updateStateWithTestCheck — test profile flag save failed', error: e);
      }

      final path = TestProfileConfig.faceImagePath;
      final file = File(path);

      ref.read(avatarProvider.notifier).saveFaceDraft(
        ownerId: targetUser.uid,
        imagePaths: [path],
      ).then((_) {
        AppLogger.auth.i('_updateStateWithTestCheck — test profile face uploaded to D-ID');
      }).catchError((e) {
        AppLogger.auth.w('_updateStateWithTestCheck — test profile face upload failed (non-blocking)', error: e);
      });

      _firebaseService.uploadAvatarPreviewImage(
        ownerId: targetUser.uid,
        file: file,
      ).then((publicUrl) {
        AppLogger.auth.i('_updateStateWithTestCheck — test profile preview uploaded url=$publicUrl');
      }).catchError((e) {
        AppLogger.auth.w('_updateStateWithTestCheck — test profile Firebase preview upload failed (non-blocking)', error: e);
      });

      ref.read(avatarProvider.notifier).trainBehaviorProfile(
        ownerId: targetUser.uid,
        answers: TestProfileConfig.behavioralAnswers,
      ).then((_) {
        AppLogger.auth.i('_updateStateWithTestCheck — test profile behavior training saved');
      }).catchError((e) {
        AppLogger.auth.w('_updateStateWithTestCheck — test profile behavior training failed (non-blocking)', error: e);
      });

      final presetVoiceId = TestProfileConfig.elevenLabsVoiceId;
      final voiceSample = TestProfileConfig.voiceSamplePath;
      if (voiceSample.isNotEmpty) {
        ref.read(avatarProvider.notifier).saveVoiceDraft(
          ownerId: targetUser.uid,
          samplePath: voiceSample,
        ).then((_) {
          AppLogger.auth.i('_updateStateWithTestCheck — test profile voice cloned from sample');
        }).catchError((e) {
          AppLogger.auth.w('_updateStateWithTestCheck — test profile voice clone failed (non-blocking)', error: e);
        });
      } else if (presetVoiceId.isNotEmpty) {
        ref.read(avatarProvider.notifier).savePresetVoiceId(
          ownerId: targetUser.uid,
          voiceId: presetVoiceId,
        ).then((_) {
          AppLogger.auth.i('_updateStateWithTestCheck — test profile preset voiceId=$presetVoiceId saved');
        }).catchError((e) {
          AppLogger.auth.w('_updateStateWithTestCheck — test profile preset voiceId save failed (non-blocking)', error: e);
        });
      }
    }
    state = targetUser;
  }
}
