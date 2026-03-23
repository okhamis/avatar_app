import '../models/approval_token_model.dart';
import 'package:uuid/uuid.dart';

class TokenService {
  final Uuid _uuid = const Uuid();

  Future<AuthorizationToken> generateToken(String accountId, String sessionId, String credentialType) async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthorizationToken(
      tokenId: _uuid.v4(),
      accountId: accountId,
      sessionId: sessionId,
      credentialType: credentialType,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      timeoutSeconds: 300,
      used: false,
      invalidated: false,
      biometricRef: "bio_ref_123",
    );
  }
}
