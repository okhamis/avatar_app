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
}
