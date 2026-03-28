import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../models/heygen_streaming_session.dart';

/// LiveAvatar LITE: session token + start → LiveKit (replaces HeyGen `streaming.new`).
///
/// LITE command WebSocket (lip-sync audio) is not wired here yet; use local ElevenLabs/TTS for speech.
class LiveAvatarService {
  String? _stopSessionId;
  String? lastError;

  String? get _apiKey {
    final raw = dotenv.env['LIVEAVATAR_API_KEY']?.trim();
    if (raw == null || raw.isEmpty || raw.contains('placeholder') || raw.startsWith('your_')) {
      return null;
    }
    return raw;
  }

  /// Creates a LITE session and returns LiveKit credentials (same shape as HeyGen streaming).
  ///
  /// Stops any [active sessions](https://docs.liveavatar.com) listed for this API key first, then
  /// retries once if start still returns concurrency limit (4032)—common when a prior run crashed
  /// without calling [stopSession].
  Future<HeyGenStreamingSession?> createLiteSession() async {
    lastError = null;
    _stopSessionId = null;

    final apiKey = _apiKey;
    final avatarId = AppConfig.liveAvatarAvatarId.trim();
    if (apiKey == null) {
      lastError = 'LIVEAVATAR_API_KEY missing or placeholder in .env';
      debugPrint('LiveAvatar: $lastError');
      return null;
    }
    if (avatarId.isEmpty) {
      lastError = 'Set LIVEAVATAR_AVATAR_ID in .env (UUID from app.liveavatar.com → avatars).';
      debugPrint('LiveAvatar: $lastError');
      return null;
    }

    try {
      await _stopAllActiveSessions(apiKey);

      var result = await _tokenAndStart(apiKey, avatarId);
      if (result.session != null) return result.session;

      if (result.concurrencyLimit) {
        debugPrint('LiveAvatar: concurrency limit on start — stopping active sessions again, retry once');
        await _stopAllActiveSessions(apiKey);
        result = await _tokenAndStart(apiKey, avatarId);
        if (result.session != null) return result.session;
      }

      return null;
    } catch (e, st) {
      lastError = 'LiveAvatar error: $e';
      debugPrint('LiveAvatar exception: $e\n$st');
      return null;
    }
  }

  Future<({HeyGenStreamingSession? session, bool concurrencyLimit})> _tokenAndStart(
    String apiKey,
    String avatarId,
  ) async {
    final tokenUrl = Uri.parse('${AppConfig.liveAvatarApiBase}/v1/sessions/token');
    final tokenBody = <String, dynamic>{
      'mode': 'LITE',
      'avatar_id': avatarId,
      if (AppConfig.liveAvatarSandbox) 'is_sandbox': true,
      'video_settings': {
        'quality': AppConfig.liveAvatarVideoQuality,
        'encoding': AppConfig.liveAvatarVideoEncoding,
      },
    };

    final tokenRes = await http.post(
      tokenUrl,
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(tokenBody),
    );

    if (tokenRes.statusCode != 200) {
      lastError = _shortHttpError('sessions/token', tokenRes);
      debugPrint('LiveAvatar token error: $lastError');
      return (session: null, concurrencyLimit: false);
    }

    final tokenJson = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    final tokenData = tokenJson['data'] as Map<String, dynamic>?;
    final sessionToken = tokenData?['session_token']?.toString();
    if (sessionToken == null || sessionToken.isEmpty) {
      lastError = 'LiveAvatar token response missing session_token';
      debugPrint('LiveAvatar: $lastError — ${tokenRes.body}');
      return (session: null, concurrencyLimit: false);
    }

    final startUrl = Uri.parse('${AppConfig.liveAvatarApiBase}/v1/sessions/start');
    final startRes = await http.post(
      startUrl,
      headers: {
        'Authorization': 'Bearer $sessionToken',
        'accept': 'application/json',
      },
    );

    if (startRes.statusCode != 200 && startRes.statusCode != 201) {
      final concurrency = _isConcurrencyLimit(startRes);
      lastError = concurrency ? _concurrencyUserMessage : _shortHttpError('sessions/start', startRes);
      debugPrint('LiveAvatar start error: $lastError');
      return (session: null, concurrencyLimit: concurrency);
    }

    final startJson = jsonDecode(startRes.body) as Map<String, dynamic>;
    final data = startJson['data'] as Map<String, dynamic>?;
    final sid = data?['session_id']?.toString();
    final url = data?['livekit_url']?.toString();
    final clientToken = data?['livekit_client_token']?.toString();
    if (sid == null || sid.isEmpty || url == null || url.isEmpty || clientToken == null || clientToken.isEmpty) {
      lastError = 'LiveAvatar start response missing livekit fields';
      debugPrint('LiveAvatar: $lastError — ${startRes.body}');
      return (session: null, concurrencyLimit: false);
    }

    _stopSessionId = sid;
    debugPrint('LiveAvatar: LITE session started, session_id=$sid');
    return (
      session: HeyGenStreamingSession(
        sessionId: sid,
        liveKitUrl: url,
        accessToken: clientToken,
      ),
      concurrencyLimit: false,
    );
  }

  Future<void> _stopAllActiveSessions(String apiKey) async {
    final ids = await _listActiveSessionIds(apiKey);
    if (ids.isEmpty) return;
    debugPrint('LiveAvatar: stopping ${ids.length} active session(s) before start');
    for (final id in ids) {
      try {
        await _stopRemoteSession(apiKey, id);
      } catch (e) {
        debugPrint('LiveAvatar: stop $id failed: $e');
      }
    }
  }

  Future<List<String>> _listActiveSessionIds(String apiKey) async {
    final uri = Uri.parse('${AppConfig.liveAvatarApiBase}/v1/sessions').replace(
      queryParameters: {'type': 'active', 'page': '1', 'page_size': '100'},
    );
    final res = await http.get(
      uri,
      headers: {
        'X-API-KEY': apiKey,
        'accept': 'application/json',
      },
    );
    if (res.statusCode != 200) {
      debugPrint('LiveAvatar list sessions HTTP ${res.statusCode}: ${res.body.length > 200 ? '${res.body.substring(0, 200)}…' : res.body}');
      return [];
    }
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>?;
      if (results == null) return [];
      final ids = <String>[];
      for (final item in results) {
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString();
          if (id != null && id.isNotEmpty) ids.add(id);
        }
      }
      return ids;
    } catch (e) {
      debugPrint('LiveAvatar list sessions parse error: $e');
      return [];
    }
  }

  Future<void> _stopRemoteSession(String apiKey, String sessionId) async {
    await http.post(
      Uri.parse('${AppConfig.liveAvatarApiBase}/v1/sessions/stop'),
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'reason': 'USER_CLOSED',
      }),
    );
  }

  Future<void> stopSession() async {
    final sid = _stopSessionId;
    if (sid == null) return;
    final apiKey = _apiKey;
    _stopSessionId = null;
    if (apiKey == null) return;

    try {
      await _stopRemoteSession(apiKey, sid);
    } catch (e) {
      debugPrint('LiveAvatar stop exception: $e');
    }
  }

  static bool _isConcurrencyLimit(http.Response res) {
    if (res.statusCode != 403) return false;
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['code'] == 4032;
    } catch (_) {
      return res.body.contains('4032') || res.body.contains('concurrency');
    }
  }

  @visibleForTesting
  static bool debugIsConcurrencyLimitResponse(http.Response res) => _isConcurrencyLimit(res);

  static const String _concurrencyUserMessage =
      'LiveAvatar: session limit reached. Close other sessions (or another app tab), wait a minute, then try again.';

  static String _shortHttpError(String path, http.Response res) {
    var b = res.body.length > 200 ? '${res.body.substring(0, 200)}…' : res.body;
    return 'LiveAvatar $path HTTP ${res.statusCode}: $b';
  }
}
