import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref.watch(firebaseServiceProvider));
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final FirebaseService _firebaseService;
  AuthNotifier(this._firebaseService) : super(null);

  Future<void> login(String email, String password) async {
    final user = await _firebaseService.getUserProfile("mock_uid");
    state = user;
  }
  
  void logout() {
    state = null;
  }
}
