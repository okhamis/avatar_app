class PosthumousConsentRecord {
  final String recordId;
  final String accountId;
  final DateTime signedAt;
  final String digitalSignature;
  final String recordHash;
  final bool immutableAfterDeath;
  final List<String> beneficiaries;
  final List<String> blockedActions;
  final String? trustedOverseerId;
  final int overseerResponseHours;
  final String defaultOnNoResponse;

  PosthumousConsentRecord({
    required this.recordId,
    required this.accountId,
    required this.signedAt,
    required this.digitalSignature,
    required this.recordHash,
    required this.immutableAfterDeath,
    required this.beneficiaries,
    required this.blockedActions,
    this.trustedOverseerId,
    required this.overseerResponseHours,
    required this.defaultOnNoResponse,
  });
}
