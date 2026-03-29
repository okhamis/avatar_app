import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../models/approval_token_model.dart';
import '../models/avatar_model.dart';
import '../models/credential_model.dart';

import '../models/policy_record_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  FirebaseAuth get _auth {
    _ensureFirebaseInitialized();
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    _ensureFirebaseInitialized();
    return FirebaseFirestore.instance;
  }

  void _ensureFirebaseInitialized() {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'no-app',
        message: 'Firebase is not configured. Add Firebase config files and initialize Firebase before auth.',
      );
    }
  }

  Future<UserModel> getUserProfile(String uid) async {
    AppLogger.firebase.d('getUserProfile uid=$uid');
    try {
      final doc = await _firestore.collection(AppConfig.firestoreUsersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        AppLogger.firebase.d('getUserProfile OK uid=$uid');
        return UserModel.fromMap(uid, doc.data()!);
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'User profile not found.',
      );
    } catch (e) {
      AppLogger.firebase.e('getUserProfile failed uid=$uid', error: e);
      rethrow;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    AppLogger.firebase.d('saveUserProfile uid=${user.uid}');
    try {
      final data = user.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'schemaVersion': 2,
        });
      await _firestore.collection(AppConfig.firestoreUsersCollection).doc(user.uid).set(data, SetOptions(merge: true));
      AppLogger.firebase.d('saveUserProfile OK uid=${user.uid}');
    } catch (e) {
      AppLogger.firebase.e('saveUserProfile failed uid=${user.uid}', error: e);
      rethrow;
    }
  }

  Future<void> updateUserTrainingFlags({
    required String uid,
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) async {
    AppLogger.firebase.d('updateUserTrainingFlags uid=$uid face=$hasFaceTrained voice=$hasVoiceCloned behavior=$hasBehaviorTrained isLive=$isLive');
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      };
      if (hasFaceTrained != null) updates['hasFaceTrained'] = hasFaceTrained;
      if (hasVoiceCloned != null) updates['hasVoiceCloned'] = hasVoiceCloned;
      if (hasBehaviorTrained != null) updates['hasBehaviorTrained'] = hasBehaviorTrained;
      if (isLive != null) updates['isLive'] = isLive;
      await _firestore.collection(AppConfig.firestoreUsersCollection).doc(uid).set(updates, SetOptions(merge: true));
      AppLogger.firebase.d('updateUserTrainingFlags OK uid=$uid');
    } catch (e) {
      AppLogger.firebase.e('updateUserTrainingFlags failed uid=$uid', error: e);
      rethrow;
    }
  }

  Future<AvatarModel?> getAvatarProfile(String ownerId) async {
    AppLogger.firebase.d('getAvatarProfile ownerId=$ownerId');
    try {
      final doc = await _firestore.collection(AppConfig.firestoreAvatarsCollection).doc(ownerId).get();
      if (!doc.exists || doc.data() == null) {
        AppLogger.firebase.d('getAvatarProfile not found ownerId=$ownerId');
        return null;
      }
      AppLogger.firebase.d('getAvatarProfile OK ownerId=$ownerId');
      return AvatarModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      AppLogger.firebase.e('getAvatarProfile failed ownerId=$ownerId', error: e);
      rethrow;
    }
  }

  Future<void> saveAvatarProfile(AvatarModel avatar) async {
    AppLogger.firebase.d('saveAvatarProfile ownerId=${avatar.ownerId} status=${avatar.status}');
    try {
      final data = avatar.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': avatar.createdAt.toIso8601String(),
        });
      await _firestore.collection(AppConfig.firestoreAvatarsCollection).doc(avatar.ownerId).set(data, SetOptions(merge: true));
      AppLogger.firebase.d('saveAvatarProfile OK ownerId=${avatar.ownerId}');
    } catch (e) {
      AppLogger.firebase.e('saveAvatarProfile failed ownerId=${avatar.ownerId}', error: e);
      rethrow;
    }
  }

  /// Uploads a local JPEG/PNG to Storage and returns a download URL for stable cross-session preview.
  /// Returns null if Firebase is unavailable, the file is missing, or upload fails (caller keeps local path).
  Future<String?> uploadAvatarPreviewImage({
    required String ownerId,
    required File file,
  }) async {
    if (!await file.exists()) return null;
    AppLogger.firebase.d('uploadAvatarPreviewImage ownerId=$ownerId path=${file.path}');
    try {
      _ensureFirebaseInitialized();
      final ref = FirebaseStorage.instance.ref().child(AppConfig.storageAvatarsRoot).child(ownerId).child('preview.jpg');
      final ext = file.path.toLowerCase();
      final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
      await ref.putFile(file, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();
      AppLogger.firebase.i('uploadAvatarPreviewImage OK ownerId=$ownerId url=$url');
      return url;
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') {
        AppLogger.firebase.w('uploadAvatarPreviewImage skipped — Firebase not configured');
        return null;
      }
      AppLogger.firebase.e('uploadAvatarPreviewImage failed ownerId=$ownerId', error: e);
      return null;
    } catch (e) {
      AppLogger.firebase.e('uploadAvatarPreviewImage failed ownerId=$ownerId', error: e);
      return null;
    }
  }

  // ———————————————————————— Sessions ————————————————————————

  CollectionReference<Map<String, dynamic>> _sessionsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreSessionsCollection);

  Future<void> saveSession(String accountId, SessionModel session) async {
    AppLogger.session.d('saveSession accountId=$accountId sessionId=${session.sessionId}');
    try {
      await _sessionsCol(accountId).doc(session.sessionId).set(session.toMap(), SetOptions(merge: true));
      AppLogger.session.d('saveSession OK sessionId=${session.sessionId}');
    } catch (e) {
      AppLogger.session.w('saveSession failed sessionId=${session.sessionId}', error: e);
    }
  }

  Future<List<SessionModel>> getSessions(String accountId) async {
    AppLogger.session.d('getSessions accountId=$accountId');
    try {
      final snap = await _sessionsCol(accountId).orderBy('startTime', descending: true).get();
      AppLogger.session.d('getSessions OK count=${snap.docs.length}');
      return snap.docs.map((d) => SessionModel.fromMap(d.id, d.data())).toList();
    } catch (e) {
      AppLogger.session.w('getSessions failed accountId=$accountId', error: e);
      return [];
    }
  }

  Future<SessionModel?> getSession(String accountId, String sessionId) async {
    AppLogger.session.d('getSession accountId=$accountId sessionId=$sessionId');
    try {
      final doc = await _sessionsCol(accountId).doc(sessionId).get();
      if (!doc.exists || doc.data() == null) return null;
      return SessionModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      AppLogger.session.w('getSession failed sessionId=$sessionId', error: e);
      return null;
    }
  }

  // ———————————————————————— Credentials ————————————————————————

  CollectionReference<Map<String, dynamic>> _credentialsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreCredentialsCollection);

  Future<void> saveCredential(String accountId, CredentialModel cred) async {
    AppLogger.firebase.d('saveCredential accountId=$accountId credentialId=${cred.credentialId}');
    try {
      await _credentialsCol(accountId).doc(cred.credentialId).set(cred.toMap(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.firebase.w('saveCredential failed credentialId=${cred.credentialId}', error: e);
    }
  }

  Future<void> deleteCredential(String accountId, String credentialId) async {
    AppLogger.firebase.d('deleteCredential accountId=$accountId credentialId=$credentialId');
    try {
      await _credentialsCol(accountId).doc(credentialId).delete();
      AppLogger.firebase.d('deleteCredential OK credentialId=$credentialId');
    } catch (e) {
      AppLogger.firebase.w('deleteCredential failed credentialId=$credentialId', error: e);
    }
  }

  Future<List<CredentialModel>> getCredentials(String accountId) async {
    AppLogger.firebase.d('getCredentials accountId=$accountId');
    try {
      final snap = await _credentialsCol(accountId).get();
      AppLogger.firebase.d('getCredentials OK count=${snap.docs.length}');
      return snap.docs.map((d) => CredentialModel.fromMap(d.id, d.data())).toList();
    } catch (e) {
      AppLogger.firebase.w('getCredentials failed accountId=$accountId', error: e);
      return [];
    }
  }

  // ———————————————————————— Policies ————————————————————————

  CollectionReference<Map<String, dynamic>> _policiesCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestorePoliciesCollection);

  Future<void> savePolicy(String accountId, PolicyRecord policy) async {
    AppLogger.firebase.d('savePolicy accountId=$accountId recordId=${policy.recordId}');
    try {
      await _policiesCol(accountId).doc(policy.recordId).set(policy.toMap(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.firebase.w('savePolicy failed recordId=${policy.recordId}', error: e);
    }
  }

  Future<List<PolicyRecord>> getPolicies(String accountId) async {
    AppLogger.firebase.d('getPolicies accountId=$accountId');
    try {
      final snap = await _policiesCol(accountId).get();
      AppLogger.firebase.d('getPolicies OK count=${snap.docs.length}');
      return snap.docs.map((d) => PolicyRecord.fromMap(d.id, d.data())).toList();
    } catch (e) {
      AppLogger.firebase.w('getPolicies failed accountId=$accountId', error: e);
      return [];
    }
  }

  // ———————————————————————— Approvals ————————————————————————

  CollectionReference<Map<String, dynamic>> _approvalsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreApprovalsCollection);

  Future<void> saveApproval(String accountId, AuthorizationToken token) async {
    AppLogger.firebase.d('saveApproval accountId=$accountId tokenId=${token.tokenId}');
    try {
      await _approvalsCol(accountId).doc(token.tokenId).set(token.toMap(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.firebase.w('saveApproval failed tokenId=${token.tokenId}', error: e);
    }
  }

  Future<List<AuthorizationToken>> getApprovals(String accountId) async {
    AppLogger.firebase.d('getApprovals accountId=$accountId');
    try {
      final snap = await _approvalsCol(accountId).get();
      AppLogger.firebase.d('getApprovals OK count=${snap.docs.length}');
      return snap.docs.map((d) => AuthorizationToken.fromMap(d.id, d.data())).toList();
    } catch (e) {
      AppLogger.firebase.w('getApprovals failed accountId=$accountId', error: e);
      return [];
    }
  }

  // ———————————————————————— Auth ————————————————————————

  Future<UserCredential> signInWithEmail(String email, String password) async {
    AppLogger.auth.d('signInWithEmail email=$email');
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      AppLogger.auth.i('signInWithEmail OK uid=${result.user?.uid}');
      return result;
    } catch (e) {
      AppLogger.auth.e('signInWithEmail failed email=$email', error: e);
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmail(String email, String password) async {
    AppLogger.auth.d('createUserWithEmail email=$email');
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      AppLogger.auth.i('createUserWithEmail OK uid=${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      AppLogger.auth.w('createUserWithEmail FirebaseAuthException code=${e.code}', error: e.message);
      rethrow;
    } catch (e) {
      AppLogger.auth.e('createUserWithEmail failed email=$email', error: e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    AppLogger.auth.d('signInWithGoogle');
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      AppLogger.auth.i('signInWithGoogle OK uid=${result.user?.uid}');
      return result;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      AppLogger.auth.e('signInWithGoogle failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    AppLogger.auth.d('signInWithFacebook');
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success || loginResult.accessToken == null) {
        throw FirebaseAuthException(
          code: 'facebook-login-failed',
          message: loginResult.message ?? 'Facebook sign-in did not complete.',
        );
      }
      final credential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      final result = await _auth.signInWithCredential(credential);
      AppLogger.auth.i('signInWithFacebook OK uid=${result.user?.uid}');
      return result;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      AppLogger.auth.e('signInWithFacebook failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLogger.auth.i('signOut initiated');
    Exception? lastError;
    try {
      await _auth.signOut();
    } catch (e) {
      AppLogger.auth.e('FirebaseAuth signOut failed', error: e);
      lastError = Exception("FirebaseAuth Logout Error: $e");
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      AppLogger.auth.w('GoogleSignIn signOut failed', error: e);
      lastError ??= Exception("GoogleSignIn Logout Error: $e");
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      AppLogger.auth.w('FacebookAuth logOut failed', error: e);
      lastError ??= Exception("FacebookAuth Logout Error: $e");
    }

    if (lastError != null) throw lastError;
    AppLogger.auth.i('signOut complete');
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    AppLogger.auth.d('signInWithCredential provider=${credential.providerId}');
    try {
      final result = await _auth.signInWithCredential(credential);
      AppLogger.auth.i('signInWithCredential OK uid=${result.user?.uid}');
      return result;
    } catch (e) {
      AppLogger.auth.e('signInWithCredential failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential> linkCurrentUserWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to link provider to.',
      );
    }
    AppLogger.auth.d('linkCurrentUserWithCredential uid=${user.uid} provider=${credential.providerId}');
    try {
      final result = await user.linkWithCredential(credential);
      AppLogger.auth.i('linkCurrentUserWithCredential OK uid=${user.uid}');
      return result;
    } catch (e) {
      AppLogger.auth.e('linkCurrentUserWithCredential failed uid=${user.uid}', error: e);
      rethrow;
    }
  }
}
