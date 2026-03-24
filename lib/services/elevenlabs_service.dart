import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';

class ElevenLabsService {
  Future<String> cloneVoice(String audioFilePath) async {
    // Voice cloning uses a separate multipart upload endpoint.
    // Simulating locally to avoid unnecessary API consumption during tests.
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('Simulated Voice Clone initiated.');
    return 'voice_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Returns a local file path with synthesized audio, or empty string if unavailable.
  Future<String> generateSpeech(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      debugPrint('Missing ElevenLabs API Key; no audio file produced.');
      return '';
    }

    final voiceId = AppConfig.elevenLabsVoiceId;
    final uri = Uri.parse('${AppConfig.elevenLabsTtsBaseUrl}/$voiceId');

    try {
      final response = await http.post(
        uri,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': text,
          'model_id': AppConfig.elevenLabsModelId,
          'voice_settings': {
            'stability': AppConfig.elevenLabsStability,
            'similarity_boost': AppConfig.elevenLabsSimilarityBoost,
          },
        }),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/elevenlabs_output_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
      debugPrint('ElevenLabs API Error: ${response.statusCode}');
      return '';
    } catch (e) {
      debugPrint('ElevenLabs Exception: $e');
      return '';
    }
  }
}
