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
}
