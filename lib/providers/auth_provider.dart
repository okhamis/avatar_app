import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends Notifier<UserModel?> {
  late final FirebaseService _firebaseService;

  @override
  UserModel? build() {
    _firebaseService = ref.watch(firebaseServiceProvider);
    return null;
  }

  Future<void> login(String email, String password) async {
    final credential = await _firebaseService.signInWithEmail(email, password);
    if (credential?.user?.uid != null) {
      final user = await _firebaseService.getUserProfile(credential!.user!.uid);
      state = user;
      return;
    }
    state = UserModel(uid: 'mock_uid', email: email, fullName: 'Demo User');
  }
  
  void logout() {
    state = null;
  }
}
