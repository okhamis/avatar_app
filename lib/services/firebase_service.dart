import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../config/app_config.dart';
import '../models/approval_token_model.dart';
import '../models/avatar_model.dart';
import '../models/credential_model.dart';
import '../models/family_member_model.dart';
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
    try {
      final doc = await _firestore.collection(AppConfig.firestoreUsersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(uid, doc.data()!);
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'User profile not found.',
      );
    } catch (e) {
      debugPrint("Error fetching user profile from Firestore: $e");
      rethrow;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    try {
      final data = user.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'schemaVersion': 2,
        });
      await _firestore.collection(AppConfig.firestoreUsersCollection).doc(user.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user to Firestore: $e");
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
    } catch (e) {
      debugPrint("Error updating user training flags: $e");
      rethrow;
    }
  }

  Future<AvatarModel?> getAvatarProfile(String ownerId) async {
    try {
      final doc = await _firestore.collection(AppConfig.firestoreAvatarsCollection).doc(ownerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AvatarModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint("Error fetching avatar profile: $e");
      rethrow;
    }
  }

  Future<void> saveAvatarProfile(AvatarModel avatar) async {
    try {
      final data = avatar.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': avatar.createdAt.toIso8601String(),
        });
      await _firestore.collection(AppConfig.firestoreAvatarsCollection).doc(avatar.ownerId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving avatar profile: $e");
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
    try {
      _ensureFirebaseInitialized();
      final ref = FirebaseStorage.instance.ref().child(AppConfig.storageAvatarsRoot).child(ownerId).child('preview.jpg');
      final ext = file.path.toLowerCase();
      final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
      await ref.putFile(file, SettableMetadata(contentType: mime));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') {
        debugPrint('Storage preview upload skipped: Firebase not configured.');
        return null;
      }
      debugPrint('Storage preview upload failed: $e');
      return null;
    } catch (e) {
      debugPrint('Storage preview upload failed: $e');
      return null;
    }
  }

  // ———————————————————————— Sessions ————————————————————————

  CollectionReference<Map<String, dynamic>> _sessionsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreSessionsCollection);

  Future<void> saveSession(String accountId, SessionModel session) async {
    try {
      await _sessionsCol(accountId).doc(session.sessionId).set(session.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<List<SessionModel>> getSessions(String accountId) async {
    try {
      final snap = await _sessionsCol(accountId).orderBy('startTime', descending: true).get();
      return snap.docs.map((d) => SessionModel.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  Future<SessionModel?> getSession(String accountId, String sessionId) async {
    try {
      final doc = await _sessionsCol(accountId).doc(sessionId).get();
      if (!doc.exists || doc.data() == null) return null;
      return SessionModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error loading session: $e');
      return null;
    }
  }

  // ———————————————————————— Family ————————————————————————

  CollectionReference<Map<String, dynamic>> _familyCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreFamilyCollection);

  Future<void> saveFamilyMember(String accountId, FamilyMember member) async {
    try {
      await _familyCol(accountId).doc(member.memberId).set(member.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving family member: $e');
    }
  }

  Future<List<FamilyMember>> getFamilyMembers(String accountId) async {
    try {
      final snap = await _familyCol(accountId).get();
      return snap.docs.map((d) => FamilyMember.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('Error loading family members: $e');
      return [];
    }
  }

  // ———————————————————————— Credentials ————————————————————————

  CollectionReference<Map<String, dynamic>> _credentialsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreCredentialsCollection);

  Future<void> saveCredential(String accountId, CredentialModel cred) async {
    try {
      await _credentialsCol(accountId).doc(cred.credentialId).set(cred.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving credential: $e');
    }
  }

  Future<void> deleteCredential(String accountId, String credentialId) async {
    try {
      await _credentialsCol(accountId).doc(credentialId).delete();
    } catch (e) {
      debugPrint('Error deleting credential: $e');
    }
  }

  Future<List<CredentialModel>> getCredentials(String accountId) async {
    try {
      final snap = await _credentialsCol(accountId).get();
      return snap.docs.map((d) => CredentialModel.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      return [];
    }
  }

  // ———————————————————————— Policies ————————————————————————

  CollectionReference<Map<String, dynamic>> _policiesCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestorePoliciesCollection);

  Future<void> savePolicy(String accountId, PolicyRecord policy) async {
    try {
      await _policiesCol(accountId).doc(policy.recordId).set(policy.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving policy: $e');
    }
  }

  Future<List<PolicyRecord>> getPolicies(String accountId) async {
    try {
      final snap = await _policiesCol(accountId).get();
      return snap.docs.map((d) => PolicyRecord.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('Error loading policies: $e');
      return [];
    }
  }

  // ———————————————————————— Approvals ————————————————————————

  CollectionReference<Map<String, dynamic>> _approvalsCol(String accountId) =>
      _firestore.collection(AppConfig.firestoreUsersCollection).doc(accountId).collection(AppConfig.firestoreApprovalsCollection);

  Future<void> saveApproval(String accountId, AuthorizationToken token) async {
    try {
      await _approvalsCol(accountId).doc(token.tokenId).set(token.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving approval: $e');
    }
  }

  Future<List<AuthorizationToken>> getApprovals(String accountId) async {
    try {
      final snap = await _approvalsCol(accountId).get();
      return snap.docs.map((d) => AuthorizationToken.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('Error loading approvals: $e');
      return [];
    }
  }

  // ———————————————————————— Auth ————————————————————————

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("FirebaseAuth Login Error: $e");
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuth Signup Error [${e.code}]: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("FirebaseAuth Signup Error: $e");
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      rethrow;
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success || loginResult.accessToken == null) {
        throw FirebaseAuthException(
          code: 'facebook-login-failed',
          message: loginResult.message ?? 'Facebook sign-in did not complete.',
        );
      }
      final credential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint("Facebook sign-in error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    Exception? lastError;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("FirebaseAuth Logout Error: $e");
      lastError = Exception("FirebaseAuth Logout Error: $e");
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("GoogleSignIn Logout Error: $e");
      lastError ??= Exception("GoogleSignIn Logout Error: $e");
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint("FacebookAuth Logout Error: $e");
      lastError ??= Exception("FacebookAuth Logout Error: $e");
    }

    if (lastError != null) throw lastError;
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Sign-in with credential error: $e");
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
    try {
      return await user.linkWithCredential(credential);
    } catch (e) {
      debugPrint("Link credential error: $e");
      rethrow;
    }
  }
}
