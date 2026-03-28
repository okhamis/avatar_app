class SessionModel {
  final String sessionId;
  final String avatarId;
  final String targetContactName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isLive;
  final String status;
  final List<Map<String, dynamic>> transcript;
  final List<String> actionsTaken;

  SessionModel({
    required this.sessionId,
    required this.avatarId,
    required this.targetContactName,
    required this.startTime,
    this.endTime,
    required this.isLive,
    required this.status,
    required this.transcript,
    required this.actionsTaken,
  });

  Map<String, dynamic> toMap() => {
        'avatarId': avatarId,
        'targetContactName': targetContactName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isLive': isLive,
        'status': status,
        'transcript': transcript,
        'actionsTaken': actionsTaken,
      };

  factory SessionModel.fromMap(String id, Map<String, dynamic> d) => SessionModel(
        sessionId: id,
        avatarId: (d['avatarId'] as String?) ?? '',
        targetContactName: (d['targetContactName'] as String?) ?? '',
        startTime: DateTime.tryParse(d['startTime'] as String? ?? '') ?? DateTime.now(),
        endTime: d['endTime'] != null ? DateTime.tryParse(d['endTime'] as String) : null,
        isLive: (d['isLive'] as bool?) ?? false,
        status: (d['status'] as String?) ?? 'completed',
        transcript: List<Map<String, dynamic>>.from(d['transcript'] ?? []),
        actionsTaken: List<String>.from(d['actionsTaken'] ?? []),
      );
}
