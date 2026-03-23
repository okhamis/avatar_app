class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final bool hasFaceTrained;
  final bool hasVoiceCloned;
  final bool hasBehaviorTrained;
  final bool isLive;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.hasFaceTrained = false,
    this.hasVoiceCloned = false,
    this.hasBehaviorTrained = false,
    this.isLive = false,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    bool? hasFaceTrained,
    bool? hasVoiceCloned,
    bool? hasBehaviorTrained,
    bool? isLive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      hasFaceTrained: hasFaceTrained ?? this.hasFaceTrained,
      hasVoiceCloned: hasVoiceCloned ?? this.hasVoiceCloned,
      hasBehaviorTrained: hasBehaviorTrained ?? this.hasBehaviorTrained,
      isLive: isLive ?? this.isLive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'hasFaceTrained': hasFaceTrained,
      'hasVoiceCloned': hasVoiceCloned,
      'hasBehaviorTrained': hasBehaviorTrained,
      'isLive': isLive,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? 'Unknown User',
      hasFaceTrained: (data['hasFaceTrained'] as bool?) ?? false,
      hasVoiceCloned: (data['hasVoiceCloned'] as bool?) ?? false,
      hasBehaviorTrained: (data['hasBehaviorTrained'] as bool?) ?? false,
      isLive: (data['isLive'] as bool?) ?? false,
    );
  }
}
