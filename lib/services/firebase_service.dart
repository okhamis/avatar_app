import '../models/user_model.dart';
import '../models/credential_model.dart';
import '../models/policy_record_model.dart';

class FirebaseService {
  Future<UserModel> getUserProfile(String uid) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(uid: uid, email: "user@example.com", fullName: "Test User");
  }

  Future<void> saveUserProfile(UserModel user) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
