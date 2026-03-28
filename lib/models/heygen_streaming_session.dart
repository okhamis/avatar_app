/// LiveKit room credentials (HeyGen `streaming.new` or LiveAvatar `sessions/start`).
class HeyGenStreamingSession {
  const HeyGenStreamingSession({
    required this.sessionId,
    required this.liveKitUrl,
    required this.accessToken,
  });

  final String sessionId;
  final String liveKitUrl;
  final String accessToken;
}
