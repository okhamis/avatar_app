class FamilyMember {
  final String memberId;
  final String accountId;
  final String name;
  final String relationship;
  final int accessTier;
  final String? photoUrl;
  final DateTime addedAt;
  final DateTime? lastActivity;

  FamilyMember({
    required this.memberId,
    required this.accountId,
    required this.name,
    required this.relationship,
    required this.accessTier,
    this.photoUrl,
    required this.addedAt,
    this.lastActivity,
  });

  Map<String, dynamic> toMap() => {
        'accountId': accountId,
        'name': name,
        'relationship': relationship,
        'accessTier': accessTier,
        'photoUrl': photoUrl,
        'addedAt': addedAt.toIso8601String(),
        'lastActivity': lastActivity?.toIso8601String(),
      };

  factory FamilyMember.fromMap(String id, Map<String, dynamic> d) => FamilyMember(
        memberId: id,
        accountId: (d['accountId'] as String?) ?? '',
        name: (d['name'] as String?) ?? '',
        relationship: (d['relationship'] as String?) ?? '',
        accessTier: (d['accessTier'] as num?)?.toInt() ?? 2,
        photoUrl: d['photoUrl'] as String?,
        addedAt: DateTime.tryParse(d['addedAt'] as String? ?? '') ?? DateTime.now(),
        lastActivity: d['lastActivity'] != null ? DateTime.tryParse(d['lastActivity'] as String) : null,
      );
}
