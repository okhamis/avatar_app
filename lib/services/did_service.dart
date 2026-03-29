import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../core/utils/app_logger.dart';
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
  // Image upload — uploads a local face photo to D-ID /images
  // ---------------------------------------------------------------------------

  /// Uploads a local image file to D-ID's `/images` endpoint and returns the
  /// D-ID URL (typically `s3://...`) that can be used as `source_url` in
  /// streaming sessions.
  ///
  /// Returns `null` on failure.
  Future<String?> uploadImage(String localFilePath) async {
    lastError = null;
    final apiKey = _apiKey;
    AppLogger.did.d('[1] uploadImage — INPUT: localFilePath=$localFilePath');

    if (apiKey == null) {
      lastError = 'DID_API_KEY missing or invalid in .env';
      AppLogger.did.w('[1] uploadImage — FAIL: $lastError');
      return null;
    }

    final file = File(localFilePath);
    if (!file.existsSync()) {
      lastError = 'Image file not found: $localFilePath';
      AppLogger.did.w('[1] uploadImage — FAIL: $lastError');
      return null;
    }
    AppLogger.did.d('[1] uploadImage — file exists, size=${file.lengthSync()} bytes');

    final authHeader = didBasicAuthorizationHeader(apiKey);
    if (authHeader == null) {
      lastError = 'Could not build auth header';
      AppLogger.did.w('[1] uploadImage — FAIL: $lastError');
      return null;
    }

    try {
      final uri = Uri.parse('${AppConfig.didApiBase}/images');
      AppLogger.did.d('[1] uploadImage — REQUEST: POST $uri');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = authHeader;
      request.headers['accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('image', localFilePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.did.d('[1] uploadImage — RESPONSE: HTTP ${response.statusCode} body=${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final url = json['url']?.toString() ?? '';
        final id = json['id']?.toString() ?? '';
        if (url.isNotEmpty) {
          AppLogger.did.i('[1] uploadImage — SUCCESS: id=$id url=$url');
          return url;
        }
        lastError = 'D-ID /images returned empty URL';
        AppLogger.did.w('[1] uploadImage — FAIL: $lastError — body=${response.body}');
        return null;
      }

      lastError = 'HTTP ${response.statusCode}: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}';
      AppLogger.did.w('[1] uploadImage — FAIL: $lastError');
      return null;
    } catch (e) {
      lastError = 'Network error: $e';
      AppLogger.did.e('[1] uploadImage — EXCEPTION', error: e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Studio mode — Agents API
  // ---------------------------------------------------------------------------

  /// Creates a new WebRTC session via the **Agents API** (Studio mode).
  Future<Map<String, dynamic>?> createStream() async {
    lastError = null;
    AppLogger.did.d('[2] createStream (Studio/Agents) — INPUT: agentId=$_agentId');
    final headers = _authHeaders;
    if (headers == null) {
      lastError = 'DID_API_KEY missing or invalid in .env';
      AppLogger.did.w('[2] createStream — FAIL: $lastError');
      return null;
    }

    final agentId = _agentId;
    if (agentId == null) {
      lastError = 'DID_AGENT_ID missing in .env';
      AppLogger.did.w('[2] createStream — FAIL: $lastError');
      return null;
    }

    _activeBase = _agentsBase();
    AppLogger.did.d('[2] createStream — REQUEST: POST $_activeBase body={compatibility_mode:on, stream_warmup:false}');
    final result = await _postCreate(_activeBase!, headers, {
      'compatibility_mode': 'on',
      'stream_warmup': false,
    });
    if (result != null) {
      AppLogger.did.i('[2] createStream — OK id=${result["id"]} session_id=${result["session_id"]}');
    } else {
      AppLogger.did.w('[2] createStream — NULL result lastError=$lastError');
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Custom Pipeline mode — Talks/Streams API
  // ---------------------------------------------------------------------------

  /// Creates a new WebRTC session via the **Talks/Streams API** (Custom mode).
  ///
  /// [sourceUrl] must be a public HTTPS URL of the user's face photo.
  /// D-ID does NOT accept base64 data URIs or local file paths — only public
  /// HTTPS URLs (e.g. S3, Firebase Storage, etc.).
  ///
  /// If [sourceUrl] is a local file path (starts with '/'), it is rejected
  /// and the caller should fall back to [AppConfig.didSourceUrl] from .env.
  Future<Map<String, dynamic>?> createCustomStream({required String sourceUrl}) async {
    lastError = null;
    AppLogger.did.d('[3] createCustomStream — INPUT: sourceUrl=$sourceUrl');
    final headers = _authHeaders;
    if (headers == null) {
      lastError = 'DID_API_KEY missing or invalid in .env';
      AppLogger.did.w('[3] createCustomStream — FAIL: $lastError');
      return null;
    }

    if (sourceUrl.isEmpty) {
      lastError = 'No face photo URL — complete Custom Pipeline onboarding first';
      AppLogger.did.w('[3] createCustomStream — FAIL: $lastError');
      return null;
    }

    if (sourceUrl.startsWith('/') || sourceUrl.startsWith('data:')) {
      lastError = 'D-ID requires a public HTTPS or s3:// URL, got local/data URI';
      AppLogger.did.w('[3] createCustomStream — FAIL: $lastError');
      return null;
    }

    _activeBase = _talksBase();
    AppLogger.did.d('[3] createCustomStream — REQUEST: POST $_activeBase body={source_url:$sourceUrl, compatibility_mode:on, stream_warmup:false}');
    final result = await _postCreate(_activeBase!, headers, {
      'source_url': sourceUrl,
      'compatibility_mode': 'on',
      'stream_warmup': false,
    });
    if (result != null) {
      AppLogger.did.i('[3] createCustomStream — OK id=${result["id"]} session_id=${result["session_id"]}');
    } else {
      AppLogger.did.w('[3] createCustomStream — NULL — lastError=$lastError');
    }
    return result;
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
      AppLogger.did.d('[_postCreate] RESPONSE: HTTP ${res.statusCode} — ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      lastError = 'HTTP ${res.statusCode}: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}';
      return null;
    } catch (e) {
      lastError = 'Network error: $e';
      AppLogger.did.e('[_postCreate] EXCEPTION', error: e);
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
    AppLogger.did.d('[4] startStream (SDP) — INPUT: url=$url streamId=$streamId sessionId=$sessionId answerType=${answer["type"]}');
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'session_id': sessionId, 'answer': answer}),
      );
      AppLogger.did.d('[4] startStream — RESPONSE: HTTP ${res.statusCode} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppLogger.did.i('[4] startStream — SDP exchange OK streamId=$streamId');
        return true;
      }
      AppLogger.did.w('[4] startStream — FAIL HTTP ${res.statusCode}');
      return false;
    } catch (e) {
      AppLogger.did.e('[4] startStream — EXCEPTION', error: e);
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
    AppLogger.did.d('[5] submitIceCandidate — streamId=$streamId sdpMid=$sdpMid sdpMLineIndex=$sdpMLineIndex candidate=${candidate.length > 80 ? candidate.substring(0, 80) : candidate}');
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'candidate': candidate,
          'sdpMid': sdpMid,
          'sdpMLineIndex': sdpMLineIndex,
        }),
      );
      AppLogger.did.d('[5] submitIceCandidate — RESPONSE HTTP ${res.statusCode}');
    } catch (e) {
      AppLogger.did.e('[5] submitIceCandidate — EXCEPTION', error: e);
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
    AppLogger.did.d('[6] sendTask — url=$url text="${text.length > 60 ? text.substring(0, 60) : text}" voiceProvider=${voiceProvider ?? "microsoft"} voiceId=${voiceId ?? "en-US-GuyNeural"}');
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
      AppLogger.did.d('[6] sendTask — RESPONSE HTTP ${res.statusCode} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    } catch (e) {
      AppLogger.did.e('[6] sendTask — EXCEPTION', error: e);
    }
  }

  /// Closes the WebRTC session gracefully.
  Future<void> deleteStream({
    required String streamId,
    required String sessionId,
  }) async {
    final headers = _authHeaders;
    if (headers == null || _activeBase == null) return;

    AppLogger.did.d('deleteStream — streamId=$streamId');
    final url = Uri.parse('$_activeBase/$streamId');
    try {
      await http.delete(
        url,
        headers: headers,
        body: jsonEncode({'session_id': sessionId}),
      );
      AppLogger.did.i('deleteStream — OK streamId=$streamId');
    } catch (e) {
      AppLogger.did.w('deleteStream exception', error: e);
    }
  }
}
