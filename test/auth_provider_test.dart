import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_digital_twin/providers/auth_provider.dart';
import 'package:ai_digital_twin/services/firebase_service.dart';
import 'package:ai_digital_twin/core/providers/service_providers.dart';
import 'package:ai_digital_twin/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName = 'Test User';
  _FakeUser(this.uid, this.email);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  final String uid;
  final String? email;
  _FakeUserCredential(this.uid, this.email);

  @override
  User? get user => _FakeUser(uid, email);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseService implements FirebaseService {
  UserModel? mockUser;
  bool shouldThrow = false;
  bool didLogout = false;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (shouldThrow) throw FirebaseAuthException(code: 'invalid-email');
    return _FakeUserCredential('123', email);
  }

  @override
  Future<UserCredential> createUserWithEmail(String email, String password) async {
    if (shouldThrow) throw FirebaseAuthException(code: 'email-already-in-use');
    return _FakeUserCredential('123', email);
  }

  @override
  Future<UserModel> getUserProfile(String uid) async {
    return mockUser ?? UserModel(uid: uid, email: 'test@test.com', fullName: 'Test User');
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    mockUser = user;
  }

  @override
  Future<void> signOut() async {
    didLogout = true;
    mockUser = null;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('AuthNotifier login success', () async {
    final fakeFirebase = _FakeFirebaseService();
    final container = ProviderContainer(
      overrides: [
        firebaseServiceProvider.overrideWithValue(fakeFirebase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    
    await notifier.login('test@test.com', 'password');
    
    final state = container.read(authProvider);
    expect(state, isNotNull);
    expect(state?.uid, '123');
  });

  test('AuthNotifier login failure throws', () async {
    final fakeFirebase = _FakeFirebaseService()..shouldThrow = true;
    final container = ProviderContainer(
      overrides: [
        firebaseServiceProvider.overrideWithValue(fakeFirebase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    
    expect(
      () => notifier.login('test@test.com', 'bad'),
      throwsException,
    );
  });

  test('AuthNotifier logout clears state', () async {
    final fakeFirebase = _FakeFirebaseService();
    final container = ProviderContainer(
      overrides: [
        firebaseServiceProvider.overrideWithValue(fakeFirebase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.login('test@test.com', 'password');
    expect(container.read(authProvider)?.uid, '123');
    
    await notifier.logout();
    expect(fakeFirebase.didLogout, isTrue);
    expect(container.read(authProvider), isNull);
  });
}
