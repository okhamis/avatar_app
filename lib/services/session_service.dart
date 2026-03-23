import '../models/session_model.dart';

class SessionService {
  Future<SessionModel> startLiveSession(String avatarId, String targetContact) async {
    await Future.delayed(const Duration(seconds: 1));
    return SessionModel(
      sessionId: "session_123",
      avatarId: avatarId,
      targetContactName: targetContact,
      startTime: DateTime.now(),
      isLive: true,
      status: "active",
      transcript: [],
      actionsTaken: [],
    );
  }
}
