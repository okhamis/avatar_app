import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

final sessionServiceProvider = Provider((ref) => SessionService());

final currentSessionProvider = NotifierProvider<SessionNotifier, SessionModel?>(SessionNotifier.new);

class SessionNotifier extends Notifier<SessionModel?> {
  late final SessionService _sessionService;

  @override
  SessionModel? build() {
    _sessionService = ref.watch(sessionServiceProvider);
    return null;
  }

  Future<void> startSession(String avatarId, String contactName) async {
    final session = await _sessionService.startLiveSession(avatarId, contactName);
    state = session;
  }

  void endSession() {
    if (state != null) {
      state = SessionModel(
        sessionId: state!.sessionId,
        avatarId: state!.avatarId,
        targetContactName: state!.targetContactName,
        startTime: state!.startTime,
        endTime: DateTime.now(),
        isLive: false,
        status: "completed",
        transcript: state!.transcript,
        actionsTaken: state!.actionsTaken,
      );
    }
  }
}
