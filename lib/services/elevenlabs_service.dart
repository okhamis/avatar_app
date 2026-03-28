import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';

class ElevenLabsService {
  String? get _apiKey {
    final key = dotenv.env['ELEVENLABS_API_KEY']?.trim();
    if (key == null || key.isEmpty || key.contains('placeholder') || key.startsWith('your_')) {
      return null;
    }
    return key;
  }

  /// Clones the user's voice by uploading an audio sample to ElevenLabs.
  /// Returns the new voice_id on success, or empty string on failure.
  Future<String> cloneVoice(String audioFilePath, {String name = 'Presnt Clone'}) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      debugPrint('ElevenLabs: missing or placeholder API key — cannot clone voice');
      return '';
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      debugPrint('ElevenLabs: audio file not found: $audioFilePath');
      return '';
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.elevenlabs.io/v1/voices/add'),
      );
      request.headers['xi-api-key'] = apiKey;
      request.fields['name'] = name;
      request.fields['description'] = 'Voice clone created by Presnt app';
      request.files.add(await http.MultipartFile.fromPath('files', audioFilePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final voiceId = json['voice_id']?.toString() ?? '';
        if (voiceId.isNotEmpty) {
          debugPrint('ElevenLabs: voice cloned successfully, voice_id=$voiceId');
          return voiceId;
        }
      }
      debugPrint('ElevenLabs: clone failed HTTP ${response.statusCode} — ${response.body}');
      return '';
    } catch (e) {
      debugPrint('ElevenLabs: clone exception: $e');
      return '';
    }
  }

  /// Generates speech audio using a specific voice_id.
  /// If [voiceId] is null/empty, falls back to the default config voice.
  /// Returns a local file path with the audio, or empty string if unavailable.
  Future<String> generateSpeech(String text, {String? voiceId}) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      debugPrint('ElevenLabs: missing API key — no audio produced');
      return '';
    }

    final resolvedVoiceId = (voiceId != null && voiceId.isNotEmpty)
        ? voiceId
        : AppConfig.elevenLabsVoiceId;

    final uri = Uri.parse('${AppConfig.elevenLabsTtsBaseUrl}/$resolvedVoiceId');

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
      debugPrint('ElevenLabs TTS Error: ${response.statusCode}');
      return '';
    } catch (e) {
      debugPrint('ElevenLabs TTS Exception: $e');
      return '';
    }
  }
}
