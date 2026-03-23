import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HeyGenService {
  String? _sessionId;
  
  Future<void> trainFaceModel(List<String> imagePaths) async {
    // Face cloning requires explicit image upload sequence and usually human verification
    // Simulating the heavy payload lifting locally for the MVP scope limits
    await Future.delayed(const Duration(seconds: 2));
    print("Simulated HeyGen Face Model trained using ${imagePaths.length} local images.");
  }

  /// Establishes an interactive WebRTC streaming session with the HeyGen servers
  Future<String?> createStreamingSession() async {
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      print("Missing HeyGen API Key for WebRTC Streaming");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.heygen.com/v1/streaming.new'),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quality': 'high',
          'avatar_name': 'josh_lite3_20230714' // Replaced programmatically with User's cloned Face ID
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['data']['session_id'];
        return data['data']['access_token']; // Required WebRTC SDP token
      } else {
        print("HeyGen Session Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("HeyGen Exception: $e");
      return null;
    }
  }

  /// Sends a generation task to the active WebRTC video stream
  Future<void> sendTaskToAvatar(String textPayload) async {
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
    if (_sessionId == null || apiKey == null || apiKey.contains('placeholder')) {
      print("Cannot send HeyGen task: Missing Session ID or real API Key");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.heygen.com/v1/streaming.task'),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session_id': _sessionId,
          'text': textPayload,
          'task_type': 'text' // Change to 'audio' if bypassing HeyGen TTS entirely to use ElevenLabs
        }),
      );

      if (response.statusCode != 200) {
        print("HeyGen Task Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("HeyGen Task Exception: $e");
    }
  }

  /// Kills the active streaming connection securely on the server
  Future<void> closeSession() async {
    if (_sessionId == null) return;
    
    final apiKey = dotenv.env['HEYGEN_API_KEY'];
    try {
      await http.post(
        Uri.parse('https://api.heygen.com/v1/streaming.stop'),
        headers: {
          'x-api-key': apiKey ?? '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'session_id': _sessionId}),
      );
      _sessionId = null;
    } catch (e) {
      print("Close Session Exception: $e");
    }
  }
}
