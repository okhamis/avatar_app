import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../core/utils/app_logger.dart';
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
      AppLogger.heygen.w('_uploadAsset file not found: $imagePath');
      return null;
    }
    AppLogger.heygen.d('_uploadAsset size=${file.lengthSync()} bytes path=$imagePath');

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
          AppLogger.heygen.i('_uploadAsset OK imageKey=$imageKey');
          return imageKey;
        }
        AppLogger.heygen.w('_uploadAsset: upload succeeded but no image_key in response');
        return null;
      }
      AppLogger.heygen.w('_uploadAsset FAIL HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.heygen.e('_uploadAsset exception', error: e);
      return null;
    }
  }

  /// Uploads face photos to HeyGen, creates a Photo Avatar Group, and returns the `group_id`.
  /// This group_id can be used as `avatar_id` in streaming sessions.
  /// Returns `null` if the API key is missing or the process fails.
  Future<String?> createPhotoAvatar(List<String> imagePaths, {String name = 'Presnt Avatar'}) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      AppLogger.heygen.w('createPhotoAvatar — missing or placeholder API key');
      return null;
    }

    if (imagePaths.isEmpty) {
      AppLogger.heygen.w('createPhotoAvatar — no images provided');
      return null;
    }

    AppLogger.heygen.d('createPhotoAvatar — uploading ${imagePaths.length} face photos name=$name');
    final firstKey = await _uploadAsset(imagePaths.first);
    if (firstKey == null) {
      AppLogger.heygen.w('createPhotoAvatar — failed to upload primary face photo');
      return null;
    }

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
          AppLogger.heygen.w('createPhotoAvatar — group created but no group_id in response');
          return null;
        }
        AppLogger.heygen.i('createPhotoAvatar — photo avatar group created group_id=$groupId');
      } else {
        final snippet = response.body.length > 300
            ? '${response.body.substring(0, 300)}...'
            : response.body;
        AppLogger.heygen.w('createPhotoAvatar — group create failed HTTP ${response.statusCode}: $snippet');
        return null;
      }
    } catch (e) {
      AppLogger.heygen.e('createPhotoAvatar — group create exception', error: e);
      return null;
    }

    // Upload remaining photos and add them to the group (up to 4 at a time)
    if (imagePaths.length > 1) {
      final remaining = imagePaths.sublist(1);
      final uploadedKeys = <String>[];
      for (final path in remaining) {
        final key = await _uploadAsset(path);
        if (key != null) uploadedKeys.add(key);
      }

      if (uploadedKeys.isNotEmpty) {
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
              AppLogger.heygen.d('createPhotoAvatar — added ${batch.length} looks to group $groupId');
            } else {
              AppLogger.heygen.w('createPhotoAvatar — add looks failed HTTP ${addResponse.statusCode}');
            }
          } catch (e) {
            AppLogger.heygen.e('createPhotoAvatar — add looks exception', error: e);
          }
        }
      }
    }

    return groupId;
  }

  /// Lists available Interactive/Streaming avatars.
  Future<List<Map<String, dynamic>>> listStreamingAvatars() async {
    final apiKey = _apiKey;
    if (apiKey == null) return [];

    AppLogger.heygen.d('listStreamingAvatars — REQUEST');
    try {
      final response = await http.get(
        Uri.parse(AppConfig.heygenStreamingAvatarListUrl),
        headers: {'x-api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is List) {
          AppLogger.heygen.d('listStreamingAvatars — OK count=${data.length}');
          return data.cast<Map<String, dynamic>>();
        }
      } else {
        AppLogger.heygen.w('listStreamingAvatars — FAIL HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.heygen.e('listStreamingAvatars exception', error: e);
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
      AppLogger.heygen.w('createStreamingSession — HEYGEN_API_KEY missing or placeholder');
      return null;
    }

    final resolvedAvatarId = (avatarId?.trim().isNotEmpty == true)
        ? avatarId!.trim()
        : AppConfig.heygenStreamingAvatarId.trim();

    AppLogger.heygen.i('createStreamingSession — avatarId=${resolvedAvatarId.isEmpty ? "default" : resolvedAvatarId} voiceId=${voiceId ?? "default"}');

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
          AppLogger.heygen.w('createStreamingSession — unexpected response shape (no data object)');
          return null;
        }
        final sid = inner['session_id']?.toString();
        final url = inner['url']?.toString();
        final token = inner['access_token']?.toString();
        if (sid == null || sid.isEmpty || url == null || url.isEmpty || token == null || token.isEmpty) {
          lastStreamingSessionError = 'HeyGen response missing session_id, url, or access_token.';
          AppLogger.heygen.w('createStreamingSession — missing session_id, url, or access_token');
          return null;
        }
        _sessionId = sid;
        AppLogger.heygen.i('createStreamingSession OK sessionId=$sid avatarId=${resolvedAvatarId.isEmpty ? "default" : resolvedAvatarId} voiceId=${voiceId ?? "default"}');
        return HeyGenStreamingSession(
          sessionId: sid,
          liveKitUrl: url,
          accessToken: token,
        );
      } else {
        final snippet = response.body.length > 400
            ? '${response.body.substring(0, 400)}...'
            : response.body;
        AppLogger.heygen.w('createStreamingSession — HTTP ${response.statusCode}: $snippet');
        final short = snippet.length > 180 ? '${snippet.substring(0, 180)}…' : snippet;
        lastStreamingSessionError =
            'HeyGen HTTP ${response.statusCode}. Often: invalid avatar_id / voice (try clearing custom face in Firestore or set HEYGEN_STREAMING_AVATAR_ID). Detail: $short';
        return null;
      }
    } catch (e) {
      lastStreamingSessionError = 'HeyGen network error: $e';
      AppLogger.heygen.e('createStreamingSession exception', error: e);
      return null;
    }
  }

  /// Sends a generation task to the active WebRTC video stream.
  Future<void> sendTaskToAvatar(String textPayload) async {
    final apiKey = _apiKey;
    if (_sessionId == null || apiKey == null) {
      AppLogger.heygen.w('sendTaskToAvatar — missing sessionId or API key sessionId=$_sessionId');
      return;
    }

    AppLogger.heygen.d('sendTaskToAvatar — sessionId=$_sessionId textLen=${textPayload.length}');
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
        AppLogger.heygen.w('sendTaskToAvatar FAIL HTTP ${response.statusCode}');
      } else {
        AppLogger.heygen.d('sendTaskToAvatar OK sessionId=$_sessionId');
      }
    } catch (e) {
      AppLogger.heygen.e('sendTaskToAvatar exception', error: e);
    }
  }

  /// Kills the active streaming connection securely on the server.
  Future<void> closeSession() async {
    if (_sessionId == null) return;

    AppLogger.heygen.i('closeSession — sessionId=$_sessionId');
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
      AppLogger.heygen.i('closeSession OK sessionId=$_sessionId');
      _sessionId = null;
    } catch (e) {
      AppLogger.heygen.e('closeSession exception', error: e);
    }
  }
}
