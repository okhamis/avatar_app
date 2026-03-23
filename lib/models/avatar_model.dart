class AvatarModel {
  final String avatarId;
  final String ownerId;
  final double fidelityScore;
  final DateTime lastUpdated;
  final String voiceId;
  final String faceId;
  final String behaviorProfileId;
  final String status;

  AvatarModel({
    required this.avatarId,
    required this.ownerId,
    required this.fidelityScore,
    required this.lastUpdated,
    required this.voiceId,
    required this.faceId,
    required this.behaviorProfileId,
    required this.status,
  });
}
