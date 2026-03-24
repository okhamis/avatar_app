import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';

class HeyGenService {
  String? _sessionId;
  
  Future<String> trainFaceModel(List<String> imagePaths) async {
    // Face cloning requires explicit image upload sequence and usually human verification
    // Simulating the heavy payload lifting locally for the MVP scope limits
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Simulated HeyGen Face Model trained using ${imagePaths.length} local images.");
    return "face_${DateTime.now().millisecondsSinceEpoch}";
  }

  /// Establishes an interactive WebRTC streaming session with the HeyGen servers
  Future<String?> createStreamingSession() async {
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      debugPrint("Missing HeyGen API Key for WebRTC Streaming");
      return null;
    }

    final avatarName = AppConfig.heygenStreamingAvatarName;
    if (avatarName.isEmpty) {
      debugPrint('HeyGen streaming skipped: set HEYGEN_STREAMING_AVATAR_NAME in .env');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.heygenStreamingNewUrl),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quality': AppConfig.heygenStreamingQuality,
          'avatar_name': avatarName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['data']['session_id'];
        return data['data']['access_token']; // Required WebRTC SDP token
      } else {
        debugPrint("HeyGen Session Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("HeyGen Exception: $e");
      return null;
    }
  }

  /// Sends a generation task to the active WebRTC video stream
  Future<void> sendTaskToAvatar(String textPayload) async {
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
    if (_sessionId == null || apiKey == null || apiKey.contains('placeholder')) {
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

  /// Kills the active streaming connection securely on the server
  Future<void> closeSession() async {
    if (_sessionId == null) return;
    
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
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
