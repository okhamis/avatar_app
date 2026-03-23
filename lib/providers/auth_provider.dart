import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends Notifier<UserModel?> {
  FirebaseService get _firebaseService => ref.read(firebaseServiceProvider);

  @override
  UserModel? build() {
    return null;
  }

  Future<void> restoreSessionUser() async {
    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') {
        state = null;
        return;
      }
      rethrow;
    }
    if (firebaseUser == null) {
      state = null;
      return;
    }
    try {
      state = await _firebaseService.getUserProfile(firebaseUser.uid);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        state = UserModel(uid: firebaseUser.uid, email: firebaseUser.email ?? '', fullName: firebaseUser.displayName ?? 'User');
        await _firebaseService.saveUserProfile(state!);
        return;
      }
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final credential = await _firebaseService.signInWithEmail(email, password);
      if (credential.user?.uid != null) {
        try {
          final user = await _firebaseService.getUserProfile(credential.user!.uid);
          state = user;
        } catch (profileErr) {
          debugPrint('Firestore profile fetch failed, using basic user: $profileErr');
          state = UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? email,
            fullName: credential.user!.displayName ?? 'User',
          );
        }
        return;
      }
      if (!kDebugMode) {
        throw Exception('Login failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Login FirebaseAuthException [${e.code}]: ${e.message}');
      if (!kDebugMode) {
        throw Exception(_friendlyAuthMessage(e));
      }
    } on FirebaseException catch (e) {
      debugPrint('Login FirebaseException [${e.code}]: ${e.message}');
      if (!kDebugMode) {
        throw Exception(_friendlyFirebaseMessage(e));
      }
    } catch (e) {
      debugPrint('Login unexpected error [${e.runtimeType}]: $e');
      if (!kDebugMode) {
        throw Exception('Login failed. Please try again.');
      }
    }
    if (kDebugMode) {
      state = UserModel(uid: 'mock_uid', email: email, fullName: 'Demo User');
      return;
    }
    throw Exception('Login failed. Please try again.');
  }

  Future<void> createAccount(String fullName, String email, String password) async {
    try {
      final credential = await _firebaseService.createUserWithEmail(email, password);
      final uid = credential.user?.uid;

      if (uid == null) {
        throw Exception('Unable to create account. Please try again.');
      }

      final user = UserModel(uid: uid, email: email, fullName: fullName);
      try {
        await _firebaseService.saveUserProfile(user);
      } catch (firestoreErr) {
        debugPrint('Firestore save failed (continuing with local state): $firestoreErr');
      }
      state = user;
    } on FirebaseAuthException catch (e) {
      debugPrint('createAccount FirebaseAuthException [${e.code}]: ${e.message}');
      if (kDebugMode) {
        state = UserModel(
          uid: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
        );
        return;
      }
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      debugPrint('createAccount FirebaseException [${e.code}]: ${e.message}');
      if (kDebugMode) {
        state = UserModel(
          uid: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
        );
        return;
      }
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      debugPrint('createAccount unexpected error [${e.runtimeType}]: $e');
      if (kDebugMode) {
        state = UserModel(
          uid: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
        );
        return;
      }
      throw Exception('Account creation failed. Please try again.');
    }
  }
  
  Future<void> logout() async {
    await _firebaseService.signOut();
    state = null;
  }

  Future<void> updateTrainingFlags({
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {
    final user = state;
    if (user == null) return;
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
        debugPrint('Skipping Firebase training flag save in debug mode.');
        return;
      }
      rethrow;
    }
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
}
