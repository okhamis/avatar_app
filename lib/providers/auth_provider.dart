import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../core/providers/service_providers.dart';

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
      throw Exception('Login failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Login FirebaseAuthException [${e.code}]: ${e.message}');
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      debugPrint('Login FirebaseException [${e.code}]: ${e.message}');
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      debugPrint('Login unexpected error [${e.runtimeType}]: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final credential = await _firebaseService.signInWithGoogle();
      await _syncAuthenticatedUser(credential, fallbackEmail: credential.user?.email ?? '');
    } on FirebaseAuthException catch (e) {
      debugPrint('Google login FirebaseAuthException [${e.code}]: ${e.message}');
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
      debugPrint('Google login FirebaseException [${e.code}]: ${e.message}');
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      debugPrint('Google login unexpected error [${e.runtimeType}]: $e');
      if (e.toString().contains('GIDClientID')) {
        throw Exception(
          'Google Sign-In is not configured for macOS. Add CLIENT_ID/REVERSED_CLIENT_ID to macOS GoogleService-Info.plist and set GIDClientID in macOS Info.plist.',
        );
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      final credential = await _firebaseService.signInWithFacebook();
      await _syncAuthenticatedUser(credential, fallbackEmail: credential.user?.email ?? '');
    } on FirebaseAuthException catch (e) {
      debugPrint('Facebook login FirebaseAuthException [${e.code}]: ${e.message}');
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
      debugPrint('Facebook login FirebaseException [${e.code}]: ${e.message}');
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      debugPrint('Facebook login unexpected error [${e.runtimeType}]: $e');
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

    final emailCredential = await _firebaseService.signInWithEmail(email, password);
    try {
      final linkedCredential = await _firebaseService.linkCurrentUserWithCredential(pending);
      await _syncAuthenticatedUser(
        linkedCredential,
        fallbackEmail: linkedCredential.user?.email ?? emailCredential.user?.email ?? email,
      );
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
    debugPrint('[AUTH] createAccount called: email=$email, kDebugMode=$kDebugMode');
    try {
      debugPrint('[AUTH] Calling _firebaseService.createUserWithEmail...');
      final credential = await _firebaseService.createUserWithEmail(email, password);
      debugPrint('[AUTH] createUserWithEmail returned, uid=${credential.user?.uid}');
      final uid = credential.user?.uid;

      if (uid == null) {
        debugPrint('[AUTH] uid is null, throwing');
        throw Exception('Unable to create account. Please try again.');
      }

      final user = UserModel(uid: uid, email: email, fullName: fullName);
      try {
        await _firebaseService.saveUserProfile(user);
        debugPrint('[AUTH] saveUserProfile succeeded');
      } catch (firestoreErr) {
        debugPrint('[AUTH] Firestore save failed (continuing): $firestoreErr');
      }
      state = user;
      debugPrint('[AUTH] createAccount SUCCESS, state set');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] FirebaseAuthException [${e.code}]: ${e.message}');
      throw Exception(_friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      debugPrint('[AUTH] FirebaseException [${e.code}]: ${e.message}');
      throw Exception(_friendlyFirebaseMessage(e));
    } catch (e) {
      debugPrint('[AUTH] Unexpected error [${e.runtimeType}]: $e');
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

  Future<void> _syncAuthenticatedUser(
    UserCredential credential, {
    required String fallbackEmail,
  }) async {
    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Login failed. Please try again.');
    }
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
    state = user;
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
}
