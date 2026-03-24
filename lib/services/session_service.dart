import 'package:uuid/uuid.dart';

import '../models/session_model.dart';

class SessionService {
  final Uuid _uuid = const Uuid();

  Future<SessionModel> startLiveSession(String avatarId, String targetContact) async {
    await Future.delayed(const Duration(seconds: 1));
    return SessionModel(
      sessionId: _uuid.v4(),
      avatarId: avatarId,
      targetContactName: targetContact,
      startTime: DateTime.now(),
      isLive: true,
      status: 'active',
      transcript: [],
      actionsTaken: [],
    );
  }
}
