import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../models/heygen_streaming_session.dart';

class HeyGenService {
  String? _sessionId;

  /// Last failure from [createStreamingSession] (for user-visible hints). Cleared on success.
  String? lastStreamingSessionError;

  String? get _apiKey {
    final rawKey = dotenv.env['HEYGEN_API_KEY']?.trim();
    if (rawKey == null ||
        rawKey.isEmpty ||
        rawKey.contains('placeholder') ||
        rawKey.startsWith('your_')) {
      return null;
    }
    return rawKey;
  }

  /// Uploads a single image file to HeyGen and returns the `image_key`.
  /// Returns `null` on failure.
  Future<String?> _uploadAsset(String imagePath) async {
    final apiKey = _apiKey;
    if (apiKey == null) return null;

    final file = File(imagePath);
    if (!await file.exists()) {
      debugPrint('HeyGen: file not found: $imagePath');
      return null;
    }

    final ext = imagePath.toLowerCase();
    final contentType = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';

    try {
      final bytes = await file.readAsBytes();
      final response = await http.post(
        Uri.parse(AppConfig.heygenUploadAssetUrl),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': contentType,
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final imageKey = data?['image_key']?.toString();
        if (imageKey != null && imageKey.isNotEmpty) {
          debugPrint('HeyGen: uploaded asset, image_key=$imageKey');
          return imageKey;
        }
        debugPrint('HeyGen: upload succeeded but no image_key in response');
        return null;
      }
      debugPrint('HeyGen: upload failed HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('HeyGen: upload exception: $e');
      return null;
    }
  }

  /// Uploads face photos to HeyGen, creates a Photo Avatar Group, and returns the `group_id`.
  /// This group_id can be used as `avatar_id` in streaming sessions.
  /// Returns `null` if the API key is missing or the process fails.
  Future<String?> createPhotoAvatar(List<String> imagePaths, {String name = 'Presnt Avatar'}) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      debugPrint('HeyGen: cannot create photo avatar — missing or placeholder API key');
      return null;
    }

    if (imagePaths.isEmpty) {
      debugPrint('HeyGen: no images provided for photo avatar');
      return null;
    }

    // Step 1: Upload the first image to get an image_key for group creation
    debugPrint('HeyGen: uploading ${imagePaths.length} face photos...');
    final firstKey = await _uploadAsset(imagePaths.first);
    if (firstKey == null) {
      debugPrint('HeyGen: failed to upload primary face photo');
      return null;
    }

    // Step 2: Create the Photo Avatar Group with the first image
    String? groupId;
    try {
      final response = await http.post(
        Uri.parse(AppConfig.heygenPhotoAvatarGroupCreateUrl),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'image_key': firstKey,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        groupId = data?['group_id']?.toString() ?? data?['id']?.toString();
        if (groupId == null || groupId.isEmpty) {
          debugPrint('HeyGen: avatar group created but no group_id in response');
          return null;
        }
        debugPrint('HeyGen: photo avatar group created, group_id=$groupId');
      } else {
        final snippet = response.body.length > 300
            ? '${response.body.substring(0, 300)}...'
            : response.body;
        debugPrint('HeyGen: avatar group create failed HTTP ${response.statusCode} — $snippet');
        return null;
      }
    } catch (e) {
      debugPrint('HeyGen: avatar group create exception: $e');
      return null;
    }

    // Step 3: Upload remaining photos and add them to the group (up to 4 at a time)
    if (imagePaths.length > 1) {
      final remaining = imagePaths.sublist(1);
      final uploadedKeys = <String>[];
      for (final path in remaining) {
        final key = await _uploadAsset(path);
        if (key != null) uploadedKeys.add(key);
      }

      if (uploadedKeys.isNotEmpty) {
        // HeyGen accepts up to 4 image_keys per add request
        for (var i = 0; i < uploadedKeys.length; i += 4) {
          final batch = uploadedKeys.sublist(i, (i + 4).clamp(0, uploadedKeys.length));
          try {
            final addResponse = await http.post(
              Uri.parse(AppConfig.heygenPhotoAvatarGroupAddUrl),
              headers: {
                'x-api-key': apiKey,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'group_id': groupId,
                'image_keys': batch,
                'name': name,
              }),
            );
            if (addResponse.statusCode == 200) {
              debugPrint('HeyGen: added ${batch.length} looks to group $groupId');
            } else {
              debugPrint('HeyGen: add looks failed HTTP ${addResponse.statusCode}');
            }
          } catch (e) {
            debugPrint('HeyGen: add looks exception: $e');
          }
        }
      }
    }

    return groupId;
  }

  /// Lists available Interactive/Streaming avatars. Useful for verifying
  /// whether a photo avatar is available for streaming.
  Future<List<Map<String, dynamic>>> listStreamingAvatars() async {
    final apiKey = _apiKey;
    if (apiKey == null) return [];

    try {
      final response = await http.get(
        Uri.parse(AppConfig.heygenStreamingAvatarListUrl),
        headers: {'x-api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('HeyGen: list streaming avatars exception: $e');
    }
    return [];
  }

  /// Establishes an interactive WebRTC streaming session with the HeyGen servers.
  /// [avatarId] overrides the default avatar — pass the user's photo avatar group_id
  /// to stream their custom face. Falls back to [AppConfig.heygenStreamingAvatarId].
  /// [voiceId] sets the ElevenLabs cloned voice for the streaming avatar.
  Future<HeyGenStreamingSession?> createStreamingSession({String? avatarId, String? voiceId}) async {
    lastStreamingSessionError = null;
    final apiKey = _apiKey;
    if (apiKey == null) {
      lastStreamingSessionError =
          'HEYGEN_API_KEY missing or placeholder in .env. Add a real key and fully restart the app.';
      debugPrint('HeyGen: missing or placeholder HEYGEN_API_KEY in .env');
      return null;
    }

    final resolvedAvatarId = (avatarId?.trim().isNotEmpty == true)
        ? avatarId!.trim()
        : AppConfig.heygenStreamingAvatarId.trim();

    final body = <String, dynamic>{
      'quality': AppConfig.heygenStreamingQuality,
    };
    if (resolvedAvatarId.isNotEmpty) {
      body['avatar_id'] = resolvedAvatarId;
    }
    if (voiceId != null && voiceId.trim().isNotEmpty) {
      body['voice'] = {
        'voice_id': voiceId.trim(),
        'rate': 1.0,
      };
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.heygenStreamingNewUrl),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final inner = data?['data'];
        if (inner is! Map<String, dynamic>) {
          lastStreamingSessionError = 'HeyGen returned an unexpected response (no data). Check Xcode/terminal logs.';
          debugPrint('HeyGen: unexpected response shape (no data object)');
          return null;
        }
        final sid = inner['session_id']?.toString();
        final url = inner['url']?.toString();
        final token = inner['access_token']?.toString();
        if (sid == null || sid.isEmpty || url == null || url.isEmpty || token == null || token.isEmpty) {
          lastStreamingSessionError = 'HeyGen response missing session_id, url, or access_token.';
          debugPrint('HeyGen: missing session_id, url, or access_token in response');
          return null;
        }
        _sessionId = sid;
        return HeyGenStreamingSession(
          sessionId: sid,
          liveKitUrl: url,
          accessToken: token,
        );
      } else {
        final snippet = response.body.length > 400
            ? '${response.body.substring(0, 400)}...'
            : response.body;
        debugPrint('HeyGen Session Error: HTTP ${response.statusCode} — $snippet');
        final short = snippet.length > 180 ? '${snippet.substring(0, 180)}…' : snippet;
        lastStreamingSessionError =
            'HeyGen HTTP ${response.statusCode}. Often: invalid avatar_id / voice (try clearing custom face in Firestore or set HEYGEN_STREAMING_AVATAR_ID). Detail: $short';
        return null;
      }
    } catch (e) {
      lastStreamingSessionError = 'HeyGen network error: $e';
      debugPrint("HeyGen Exception: $e");
      return null;
    }
  }

  /// Sends a generation task to the active WebRTC video stream.
  Future<void> sendTaskToAvatar(String textPayload) async {
    final apiKey = _apiKey;
    if (_sessionId == null || apiKey == null) {
      debugPrint("Cannot send HeyGen task: Missing Session ID or real API Key");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.heygenStreamingTaskUrl),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session_id': _sessionId,
          'text': textPayload,
          'task_type': AppConfig.heygenTaskType,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("HeyGen Task Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("HeyGen Task Exception: $e");
    }
  }

  /// Kills the active streaming connection securely on the server.
  Future<void> closeSession() async {
    if (_sessionId == null) return;

    final apiKey = _apiKey;
    try {
      await http.post(
        Uri.parse(AppConfig.heygenStreamingStopUrl),
        headers: {
          'x-api-key': apiKey ?? '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'session_id': _sessionId}),
      );
      _sessionId = null;
    } catch (e) {
      debugPrint("Close Session Exception: $e");
    }
  }
}
