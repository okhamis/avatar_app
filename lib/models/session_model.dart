class SessionModel {
  final String sessionId;
  final String avatarId;
  final String targetContactName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isLive;
  final String status;
  final List<dynamic> transcript;
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
}
