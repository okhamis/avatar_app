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

  Map<String, dynamic> toMap() => {
        'accountId': accountId,
        'sessionId': sessionId,
        'credentialType': credentialType,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'timeoutSeconds': timeoutSeconds,
        'used': used,
        'invalidated': invalidated,
        'biometricRef': biometricRef,
      };

  factory AuthorizationToken.fromMap(String id, Map<String, dynamic> d) => AuthorizationToken(
        tokenId: id,
        accountId: (d['accountId'] as String?) ?? '',
        sessionId: (d['sessionId'] as String?) ?? '',
        credentialType: (d['credentialType'] as String?) ?? '',
        issuedAt: DateTime.tryParse(d['issuedAt'] as String? ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(d['expiresAt'] as String? ?? '') ?? DateTime.now(),
        timeoutSeconds: (d['timeoutSeconds'] as num?)?.toInt() ?? 300,
        used: (d['used'] as bool?) ?? false,
        invalidated: (d['invalidated'] as bool?) ?? false,
        biometricRef: (d['biometricRef'] as String?) ?? '',
      );
}
