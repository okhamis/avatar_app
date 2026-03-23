enum AvatarStatus { draft, training, ready, live, error }

class AvatarModel {
  final String avatarId;
  final String ownerId;
  final double fidelityScore;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String voiceId;
  final String faceId;
  final String behaviorProfileId;
  final AvatarStatus status;
  final String? previewImagePath;
  final bool hasVoiceSample;
  final int faceSampleCount;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  AvatarModel({
    required this.avatarId,
    required this.ownerId,
    required this.fidelityScore,
    required this.createdAt,
    required this.lastUpdated,
    required this.voiceId,
    required this.faceId,
    required this.behaviorProfileId,
    required this.status,
    this.previewImagePath,
    this.hasVoiceSample = false,
    this.faceSampleCount = 0,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  AvatarModel copyWith({
    String? avatarId,
    String? ownerId,
    double? fidelityScore,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? voiceId,
    String? faceId,
    String? behaviorProfileId,
    AvatarStatus? status,
    String? previewImagePath,
    bool? hasVoiceSample,
    int? faceSampleCount,
    String? lastErrorCode,
    String? lastErrorMessage,
  }) {
    return AvatarModel(
      avatarId: avatarId ?? this.avatarId,
      ownerId: ownerId ?? this.ownerId,
      fidelityScore: fidelityScore ?? this.fidelityScore,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      voiceId: voiceId ?? this.voiceId,
      faceId: faceId ?? this.faceId,
      behaviorProfileId: behaviorProfileId ?? this.behaviorProfileId,
      status: status ?? this.status,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      hasVoiceSample: hasVoiceSample ?? this.hasVoiceSample,
      faceSampleCount: faceSampleCount ?? this.faceSampleCount,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'fidelityScore': fidelityScore,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'voiceId': voiceId,
      'faceId': faceId,
      'behaviorProfileId': behaviorProfileId,
      'status': status.name,
      'previewImagePath': previewImagePath,
      'hasVoiceSample': hasVoiceSample,
      'faceSampleCount': faceSampleCount,
      'lastErrorCode': lastErrorCode,
      'lastErrorMessage': lastErrorMessage,
      'schemaVersion': 2,
    };
  }

  factory AvatarModel.fromMap(String avatarId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic raw) {
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return AvatarModel(
      avatarId: avatarId,
      ownerId: (data['ownerId'] as String?) ?? avatarId,
      fidelityScore: (data['fidelityScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(data['createdAt']),
      lastUpdated: parseDate(data['lastUpdated']),
      voiceId: (data['voiceId'] as String?) ?? '',
      faceId: (data['faceId'] as String?) ?? '',
      behaviorProfileId: (data['behaviorProfileId'] as String?) ?? '',
      status: avatarStatusFromString(data['status'] as String?),
      previewImagePath: data['previewImagePath'] as String?,
      hasVoiceSample: (data['hasVoiceSample'] as bool?) ?? false,
      faceSampleCount: (data['faceSampleCount'] as num?)?.toInt() ?? 0,
      lastErrorCode: data['lastErrorCode'] as String?,
      lastErrorMessage: data['lastErrorMessage'] as String?,
    );
  }
}

AvatarStatus avatarStatusFromString(String? raw) {
  switch (raw) {
    case 'live':
      return AvatarStatus.live;
    case 'ready':
      return AvatarStatus.ready;
    case 'training':
      return AvatarStatus.training;
    case 'error':
      return AvatarStatus.error;
    // Backward-compatible mappings.
    case 'active':
      return AvatarStatus.live;
    case 'busy':
      return AvatarStatus.training;
    case 'sleeping':
      return AvatarStatus.ready;
    default:
      return AvatarStatus.draft;
  }
}
