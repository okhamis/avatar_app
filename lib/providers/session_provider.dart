import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../providers/auth_provider.dart';
import '../core/providers/service_providers.dart';

final sessionServiceProvider = Provider((ref) => SessionService());

final currentSessionProvider =
    NotifierProvider<SessionNotifier, SessionModel?>(SessionNotifier.new);

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
    _persist(session);
  }

  void addTranscriptEntry(Map<String, dynamic> entry) {
    if (state == null) return;
    final updated = SessionModel(
      sessionId: state!.sessionId,
      avatarId: state!.avatarId,
      targetContactName: state!.targetContactName,
      startTime: state!.startTime,
      endTime: state!.endTime,
      isLive: state!.isLive,
      status: state!.status,
      transcript: [...state!.transcript, entry],
      actionsTaken: state!.actionsTaken,
    );
    state = updated;
  }

  Future<void> endSession() async {
    if (state == null) return;
    final ended = SessionModel(
      sessionId: state!.sessionId,
      avatarId: state!.avatarId,
      targetContactName: state!.targetContactName,
      startTime: state!.startTime,
      endTime: DateTime.now(),
      isLive: false,
      status: 'completed',
      transcript: state!.transcript,
      actionsTaken: state!.actionsTaken,
    );
    state = ended;
    await _persist(ended);
  }

  Future<void> _persist(SessionModel session) async {
    final accountId = ref.read(authProvider)?.uid;
    if (accountId == null) return;
    try {
      await ref.read(firebaseServiceProvider).saveSession(accountId, session);
    } catch (e) {
      debugPrint('Failed to persist session: $e');
    }
  }
}

/// Provides the full list of past sessions for the current user.
final sessionsListProvider =
    NotifierProvider<SessionsListNotifier, List<SessionModel>>(SessionsListNotifier.new);

class SessionsListNotifier extends Notifier<List<SessionModel>> {
  @override
  List<SessionModel> build() {
    final user = ref.watch(authProvider);
    if (user != null) _load(user.uid);
    return [];
  }

  Future<void> _load(String accountId) async {
    try {
      final sessions = await ref.read(firebaseServiceProvider).getSessions(accountId);
      state = sessions;
    } catch (e) {
      debugPrint('Failed to load sessions: $e');
    }
  }

  Future<void> refresh() async {
    final accountId = ref.read(authProvider)?.uid;
    if (accountId != null) await _load(accountId);
  }
}
