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

  /// Returns the user override tier if set, otherwise the default tier.
  int get effectiveTier => userOverrideTier ?? defaultTier;

  PolicyRecord copyWith({int? userOverrideTier}) {
    return PolicyRecord(
      recordId: recordId,
      accountId: accountId,
      actionType: actionType,
      defaultTier: defaultTier,
      userOverrideTier: userOverrideTier ?? this.userOverrideTier,
      domainOverrideTier: domainOverrideTier,
      permanentlyBlocked: permanentlyBlocked,
      timeoutSeconds: timeoutSeconds,
      overrideHistory: overrideHistory,
    );
  }
}
