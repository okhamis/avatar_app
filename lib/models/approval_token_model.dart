class AuthorizationToken {
  final String tokenId;
  final String accountId;
  final String sessionId;
  final String credentialType;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int timeoutSeconds;
  final bool used;
  final bool invalidated;
  final String biometricRef;

  AuthorizationToken({
    required this.tokenId,
    required this.accountId,
    required this.sessionId,
    required this.credentialType,
    required this.issuedAt,
    required this.expiresAt,
    required this.timeoutSeconds,
    required this.used,
    required this.invalidated,
    required this.biometricRef,
  });
}
