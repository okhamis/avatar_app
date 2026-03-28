import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../utils/did_auth.dart';

/// D-ID Streaming API — supports both the **Agents API** (Studio mode) and
/// the **Talks/Streams API** (Custom Pipeline mode with user's own face+voice).
///
/// Agents API endpoints (Studio mode):
///   POST   /agents/{agentId}/streams            — create WebRTC session
///   POST   /agents/{agentId}/streams/{id}/sdp   — send SDP answer
///   POST   /agents/{agentId}/streams/{id}/ice   — submit ICE candidate
///   POST   /agents/{agentId}/streams/{id}       — speak text
///   DELETE /agents/{agentId}/streams/{id}       — close session
///
/// Talks/Streams API endpoints (Custom Pipeline mode):
///   POST   /talks/streams                       — create WebRTC session (with source_url)
///   POST   /talks/streams/{id}/sdp              — send SDP answer
///   POST   /talks/streams/{id}/ice              — submit ICE candidate
///   POST   /talks/streams/{id}                  — speak text
///   DELETE /talks/streams/{id}                  — close session
class DidService {
  String? get _apiKey {
    String? raw;
    try {
      raw = dotenv.env['DID_API_KEY']?.trim();
    } catch (_) {
      return null;
    }
    if (raw == null || raw.isEmpty || raw.contains('placeholder') || raw.startsWith('your_')) {
      return null;
    }
    return raw;
  }

  String? get _agentId {
    final id = AppConfig.didAgentId.trim();
    return id.isEmpty ? null : id;
  }

  Map<String, String>? get _authHeaders {
    final h = didBasicAuthorizationHeader(_apiKey);
    if (h == null) return null;
    return {
      'Authorization': h,
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
  }

  String _agentsBase() => '${AppConfig.didApiBase}/agents/${_agentId!}/streams';
  String _talksBase() => '${AppConfig.didApiBase}/talks/streams';

  /// The base URL used for the *current* session (set by createStream / createCustomStream).
  String? _activeBase;

  /// Last error — surfaced in the widget for debugging.
  String? lastError;

  // ---------------------------------------------------------------------------
  // Studio mode — Agents API
  // ---------------------------------------------------------------------------

  /// Creates a new WebRTC session via the **Agents API** (Studio mode).
  Future<Map<String, dynamic>?> createStream() async {
    lastError = null;
    final headers = _authHeaders;
    if (headers == null) {
      lastError = 'DID_API_KEY missing or invalid in .env';
      debugPrint('D-ID: $lastError');
      return null;
    }

    final agentId = _agentId;
    if (agentId == null) {
      lastError = 'DID_AGENT_ID missing in .env — set it to your agent ID from studio.d-id.com/agents';
      debugPrint('D-ID: $lastError');
      return null;
    }

    _activeBase = _agentsBase();
    return _postCreate(_activeBase!, headers, {
      'compatibility_mode': 'on',
      'stream_warmup': false,
    });
  }

  // ---------------------------------------------------------------------------
  // Custom Pipeline mode — Talks/Streams API
  // ---------------------------------------------------------------------------

  /// Creates a new WebRTC session via the **Talks/Streams API** (Custom mode).
  ///
  /// [sourceUrl] is the HTTPS URL of the user's face photo (from Firebase Storage).
  Future<Map<String, dynamic>?> createCustomStream({required String sourceUrl}) async {
    lastError = null;
    final headers = _authHeaders;
    if (headers == null) {
      lastError = 'DID_API_KEY missing or invalid in .env';
      debugPrint('D-ID: $lastError');
      return null;
    }

    if (sourceUrl.isEmpty) {
      lastError = 'No face photo URL — complete Custom Pipeline onboarding first';
      debugPrint('D-ID: $lastError');
      return null;
    }

    _activeBase = _talksBase();
    return _postCreate(_activeBase!, headers, {
      'source_url': sourceUrl,
      'compatibility_mode': 'on',
      'stream_warmup': false,
    });
  }

  // ---------------------------------------------------------------------------
  // Shared methods — work with both APIs (routes differ only by base path)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _postCreate(
    String base,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(base);
    try {
      final res = await http.post(url, headers: headers, body: jsonEncode(body));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      final snippet = res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body;
      lastError = 'HTTP ${res.statusCode}: $snippet';
      debugPrint('D-ID createStream error: $lastError');
      return null;
    } catch (e) {
      lastError = 'Network error: $e';
      debugPrint('D-ID createStream exception: $e');
      return null;
    }
  }

  /// Sends the WebRTC SDP answer to complete the offer/answer handshake.
  Future<bool> startStream({
    required String streamId,
    required String sessionId,
    required Map<String, dynamic> answer,
  }) async {
    final headers = _authHeaders;
    if (headers == null || _activeBase == null) return false;

    final url = Uri.parse('$_activeBase/$streamId/sdp');
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'answer': answer,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return true;
      debugPrint('D-ID startStream error: HTTP ${res.statusCode} — ${res.body}');
      return false;
    } catch (e) {
      debugPrint('D-ID startStream exception: $e');
      return false;
    }
  }

  /// Submits a local ICE candidate to the D-ID peer.
  Future<void> submitIceCandidate({
    required String streamId,
    required String sessionId,
    required String candidate,
    required int sdpMLineIndex,
    required String sdpMid,
  }) async {
    final headers = _authHeaders;
    if (headers == null || _activeBase == null) return;

    final url = Uri.parse('$_activeBase/$streamId/ice');
    try {
      await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'candidate': candidate,
          'sdpMid': sdpMid,
          'sdpMLineIndex': sdpMLineIndex,
        }),
      );
    } catch (e) {
      debugPrint('D-ID submitIceCandidate exception: $e');
    }
  }

  /// Sends a speak task — the avatar will lip-sync the provided [text].
  ///
  /// For Custom Pipeline, set [voiceProvider] to `'elevenlabs'` and [voiceId]
  /// to the user's cloned ElevenLabs voice ID.
  Future<void> sendTask({
    required String streamId,
    required String sessionId,
    required String text,
    String? voiceProvider,
    String? voiceId,
  }) async {
    final headers = _authHeaders;
    if (headers == null || _activeBase == null) return;

    final url = Uri.parse('$_activeBase/$streamId');
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'script': {
            'type': 'text',
            'input': text,
            'provider': {
              'type': voiceProvider ?? 'microsoft',
              'voice_id': voiceId ?? 'en-US-GuyNeural',
            },
          },
        }),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint(
          'D-ID sendTask HTTP ${res.statusCode}: '
          '${res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body}',
        );
      }
    } catch (e) {
      debugPrint('D-ID sendTask exception: $e');
    }
  }

  /// Closes the WebRTC session gracefully.
  Future<void> deleteStream({
    required String streamId,
    required String sessionId,
  }) async {
    final headers = _authHeaders;
    if (headers == null || _activeBase == null) return;

    final url = Uri.parse('$_activeBase/$streamId');
    try {
      await http.delete(
        url,
        headers: headers,
        body: jsonEncode({'session_id': sessionId}),
      );
    } catch (e) {
      debugPrint('D-ID deleteStream exception: $e');
    }
  }
}
