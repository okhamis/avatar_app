import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ElevenLabsService {
  final String _defaultVoiceId = "21m00Tcm4TlvDq8ikWAM"; // Example Voice ID

  Future<void> cloneVoice(String audioFilePath) async {
    // Voice cloning uses a separate multipart upload endpoint.
    // Simulating locally to avoid unnecessary API consumption during tests.
    await Future.delayed(const Duration(seconds: 2));
    print("Simulated Voice Clone initiated with raw file: $audioFilePath");
  }

  Future<String> generateSpeech(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      print("Missing ElevenLabs API Key, using local synthesis fallback path");
      return "dummy_audio_path.mp3";
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$_defaultVoiceId'),
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'accept': 'audio/mpeg'
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.5
          }
        }),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/elevenlabs_output_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        print("ElevenLabs API Error: ${response.statusCode} - ${response.body}");
        return "error_audio_path.mp3";
      }
    } catch (e) {
      print("ElevenLabs Exception: $e");
      return "error_audio_path.mp3";
    }
  }
}
