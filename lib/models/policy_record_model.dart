class PolicyRecord {
  final String recordId;
  final String accountId;
  final String actionType;
  final int defaultTier;
  final int? userOverrideTier;
  final int? domainOverrideTier;
  final bool permanentlyBlocked;
  final int timeoutSeconds;
  final List<String> overrideHistory;

  PolicyRecord({
    required this.recordId,
    required this.accountId,
    required this.actionType,
    required this.defaultTier,
    this.userOverrideTier,
    this.domainOverrideTier,
    required this.permanentlyBlocked,
    required this.timeoutSeconds,
    required this.overrideHistory,
  });
}
