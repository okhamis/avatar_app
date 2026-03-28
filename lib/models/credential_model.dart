class CredentialModel {
  final String credentialId;
  final String accountId;
  final String credentialType;
  final String maskedPreview;
  final String encryptedReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  CredentialModel({
    required this.credentialId,
    required this.accountId,
    required this.credentialType,
    required this.maskedPreview,
    required this.encryptedReference,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'accountId': accountId,
        'credentialType': credentialType,
        'maskedPreview': maskedPreview,
        'encryptedReference': encryptedReference,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CredentialModel.fromMap(String id, Map<String, dynamic> d) => CredentialModel(
        credentialId: id,
        accountId: (d['accountId'] as String?) ?? '',
        credentialType: (d['credentialType'] as String?) ?? '',
        maskedPreview: (d['maskedPreview'] as String?) ?? '',
        encryptedReference: (d['encryptedReference'] as String?) ?? '',
        createdAt: DateTime.tryParse(d['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(d['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
