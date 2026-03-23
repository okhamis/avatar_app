import '../models/approval_token_model.dart';

class TokenService {
  Future<AuthorizationToken> generateToken(String accountId, String sessionId, String credentialType) async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthorizationToken(
      tokenId: "token_123",
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
