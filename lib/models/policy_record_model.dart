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

  int get effectiveTier => userOverrideTier ?? defaultTier;

  PolicyRecord copyWith({int? userOverrideTier}) => PolicyRecord(
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

  Map<String, dynamic> toMap() => {
        'accountId': accountId,
        'actionType': actionType,
        'defaultTier': defaultTier,
        'userOverrideTier': userOverrideTier,
        'domainOverrideTier': domainOverrideTier,
        'permanentlyBlocked': permanentlyBlocked,
        'timeoutSeconds': timeoutSeconds,
        'overrideHistory': overrideHistory,
      };

  factory PolicyRecord.fromMap(String id, Map<String, dynamic> d) => PolicyRecord(
        recordId: id,
        accountId: (d['accountId'] as String?) ?? '',
        actionType: (d['actionType'] as String?) ?? '',
        defaultTier: (d['defaultTier'] as num?)?.toInt() ?? 2,
        userOverrideTier: (d['userOverrideTier'] as num?)?.toInt(),
        domainOverrideTier: (d['domainOverrideTier'] as num?)?.toInt(),
        permanentlyBlocked: (d['permanentlyBlocked'] as bool?) ?? false,
        timeoutSeconds: (d['timeoutSeconds'] as num?)?.toInt() ?? 300,
        overrideHistory: List<String>.from(d['overrideHistory'] ?? []),
      );
}
