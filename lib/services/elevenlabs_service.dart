import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../core/utils/app_logger.dart';

class ElevenLabsService {
  /// System TTS fallback used when ElevenLabs returns 401 (missing TTS permission).
  final FlutterTts _systemTts = FlutterTts();
  bool _systemTtsInitialized = false;

  Future<void> _ensureSystemTts() async {
    if (_systemTtsInitialized) return;
    if (Platform.isIOS) {
      await _systemTts.setSharedInstance(true);
    }
    _systemTtsInitialized = true;
  }

  String? get _apiKey {
    final key = dotenv.env['ELEVENLABS_API_KEY']?.trim();
    if (key == null || key.isEmpty || key.contains('placeholder') || key.startsWith('your_')) {
      AppLogger.elevenlabs.w('API key missing or placeholder (key=${key == null ? "null" : "len=${key.length}"})');
      return null;
    }
    return key;
  }

  /// Clones the user's voice by uploading an audio sample to ElevenLabs.
  /// Returns the new voice_id on success, or empty string on failure.
  Future<String> cloneVoice(String audioFilePath, {String name = 'Presnt Clone'}) async {
    AppLogger.elevenlabs.d('[CLONE] INPUT: audioFilePath=$audioFilePath name=$name');
    final apiKey = _apiKey;
    if (apiKey == null) {
      AppLogger.elevenlabs.w('[CLONE] FAIL: missing API key');
      return '';
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      AppLogger.elevenlabs.w('[CLONE] FAIL: file not found: $audioFilePath');
      return '';
    }
    AppLogger.elevenlabs.d('[CLONE] file exists, size=${file.lengthSync()} bytes');

    try {
      const url = 'https://api.elevenlabs.io/v1/voices/add';
      AppLogger.elevenlabs.d('[CLONE] REQUEST: POST $url fields={name:$name} files=[${audioFilePath.split('/').last}]');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['xi-api-key'] = apiKey;
      request.fields['name'] = name;
      request.fields['description'] = 'Voice clone created by Presnt app';
      request.files.add(await http.MultipartFile.fromPath('files', audioFilePath));

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        AppLogger.elevenlabs.w('[CLONE] TIMEOUT: no response after 30s');
        throw Exception('ElevenLabs clone timed out after 30s');
      });
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.elevenlabs.d('[CLONE] RESPONSE: HTTP ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final voiceId = json['voice_id']?.toString() ?? '';
        if (voiceId.isNotEmpty) {
          AppLogger.elevenlabs.i('[CLONE] SUCCESS: voice_id=$voiceId');
          return voiceId;
        }
      }
      AppLogger.elevenlabs.w('[CLONE] FAIL: HTTP ${response.statusCode}');
      return '';
    } catch (e) {
      AppLogger.elevenlabs.e('[CLONE] EXCEPTION', error: e);
      return '';
    }
  }

  /// Cached voice ID discovered via [fetchFirstAvailableVoiceId].
  String? _cachedVoiceId;

  /// Fetches the list of voices available to the current API key and returns
  /// the first voice ID, or empty string if none are available.
  Future<String> fetchFirstAvailableVoiceId() async {
    AppLogger.elevenlabs.d('[VOICES] REQUEST: GET https://api.elevenlabs.io/v1/voices');
    final apiKey = _apiKey;
    if (apiKey == null) {
      AppLogger.elevenlabs.w('[VOICES] FAIL: missing API key');
      return '';
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/voices'),
        headers: {'xi-api-key': apiKey},
      );
      AppLogger.elevenlabs.d('[VOICES] RESPONSE: HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final voices = json['voices'] as List<dynamic>? ?? [];
        if (voices.isNotEmpty) {
          final voiceId = (voices.first as Map<String, dynamic>)['voice_id']?.toString() ?? '';
          final voiceName = (voices.first as Map<String, dynamic>)['name']?.toString() ?? '';
          AppLogger.elevenlabs.i('[VOICES] SUCCESS: count=${voices.length} first=($voiceId, $voiceName)');
          return voiceId;
        }
        AppLogger.elevenlabs.w('[VOICES] FAIL: no voices returned');
      } else {
        AppLogger.elevenlabs.w('[VOICES] FAIL: HTTP ${response.statusCode} body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      }
      return '';
    } catch (e) {
      AppLogger.elevenlabs.e('[VOICES] EXCEPTION', error: e);
      return '';
    }
  }

  /// Generates speech audio using a specific voice_id.
  /// If [voiceId] is null/empty, falls back to the default config voice.
  /// If the voice returns 401/422, automatically discovers available voices and retries.
  /// If all ElevenLabs attempts fail, falls back to system TTS.
  /// Returns a local file path with the audio, or empty string if system TTS was used.
  Future<String> generateSpeech(String text, {String? voiceId}) async {
    final sw = Stopwatch()..start();
    AppLogger.elevenlabs.d('[SPEECH] INPUT: voiceId=${voiceId ?? "null (will use default)"} text="${text.length > 60 ? text.substring(0, 60) : text}"');
    final apiKey = _apiKey;
    if (apiKey == null) {
      AppLogger.elevenlabs.w('[SPEECH] FAIL: missing API key — using system TTS');
      await _speakWithSystemTts(text);
      return '';
    }

    final resolvedVoiceId = (voiceId != null && voiceId.isNotEmpty)
        ? voiceId
        : (_cachedVoiceId ?? AppConfig.elevenLabsVoiceId);
    AppLogger.elevenlabs.d('[SPEECH] resolved voiceId=$resolvedVoiceId (cached=$_cachedVoiceId default=${AppConfig.elevenLabsVoiceId})');

    final result = await _tryGenerateSpeech(text, resolvedVoiceId, apiKey);
    if (result.isNotEmpty) {
      AppLogger.elevenlabs.i('[SPEECH] SUCCESS on first attempt in ${sw.elapsedMilliseconds}ms: $result');
      return result;
    }

    if (_cachedVoiceId == null || _cachedVoiceId != resolvedVoiceId) {
      AppLogger.elevenlabs.d('[SPEECH] First attempt failed — fetching available voices to retry');
      final discoveredId = await fetchFirstAvailableVoiceId();
      if (discoveredId.isNotEmpty && discoveredId != resolvedVoiceId) {
        _cachedVoiceId = discoveredId;
        AppLogger.elevenlabs.d('[SPEECH] Retrying with discoveredId=$discoveredId');
        final retryResult = await _tryGenerateSpeech(text, discoveredId, apiKey);
        if (retryResult.isNotEmpty) {
          AppLogger.elevenlabs.i('[SPEECH] SUCCESS on retry in ${sw.elapsedMilliseconds}ms: $retryResult');
          return retryResult;
        }
      }
    }

    AppLogger.elevenlabs.w('[SPEECH] All ElevenLabs attempts failed — using system TTS');
    await _speakWithSystemTts(text);
    return '';
  }

  /// Speaks text using the device's built-in TTS engine as a last resort.
  Future<void> _speakWithSystemTts(String text) async {
    try {
      await _ensureSystemTts();
      await _systemTts.speak(text);
    } catch (e) {
      AppLogger.elevenlabs.e('System TTS fallback also failed', error: e);
    }
  }

  /// Internal: attempts a single TTS call with the given voice ID.
  Future<String> _tryGenerateSpeech(String text, String voiceId, String apiKey) async {
    final uri = Uri.parse('${AppConfig.elevenLabsTtsBaseUrl}/$voiceId');
    AppLogger.elevenlabs.d('[TTS] REQUEST: POST $uri model=${AppConfig.elevenLabsModelId} voiceId=$voiceId text="${text.length > 60 ? text.substring(0, 60) : text}"');

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

      AppLogger.elevenlabs.d('[TTS] RESPONSE: HTTP ${response.statusCode} bytes=${response.bodyBytes.length}${response.statusCode != 200 ? " body=${response.body}" : ""}');

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/elevenlabs_output_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(response.bodyBytes);
        AppLogger.elevenlabs.i('[TTS] SUCCESS: saved to ${file.path}');
        return file.path;
      }
      AppLogger.elevenlabs.w('[TTS] FAIL HTTP ${response.statusCode} voiceId=$voiceId');
      return '';
    } catch (e) {
      AppLogger.elevenlabs.e('[TTS] EXCEPTION', error: e);
      return '';
    }
  }

  /// Transcribes speech audio using the ElevenLabs Scribe API.
  /// Accepts a WAV file and returns the transcribed text.
  /// Returns empty string on error or if API key is missing.
  Future<String> transcribeSpeech(String audioFilePath) async {
    AppLogger.elevenlabs.d('[STT] INPUT: audioFilePath=$audioFilePath');
    final apiKey = _apiKey;
    if (apiKey == null) {
      AppLogger.elevenlabs.w('[STT] FAIL: missing API key');
      return '';
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      AppLogger.elevenlabs.w('[STT] FAIL: file not found: $audioFilePath');
      return '';
    }
    AppLogger.elevenlabs.d('[STT] file exists, size=${file.lengthSync()} bytes');

    try {
      const url = 'https://api.elevenlabs.io/v1/speech-to-text';
      AppLogger.elevenlabs.d('[STT] REQUEST: POST $url model=scribe_v1 file=${audioFilePath.split('/').last}');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['xi-api-key'] = apiKey;
      request.fields['model_id'] = 'scribe_v1';
      request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.elevenlabs.d('[STT] RESPONSE: HTTP ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = json['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          AppLogger.elevenlabs.i('[STT] SUCCESS: transcript="${text.length > 100 ? text.substring(0, 100) : text}"');
          return text;
        }
        AppLogger.elevenlabs.w('[STT] FAIL: empty transcript in response');
      }
      return '';
    } catch (e) {
      AppLogger.elevenlabs.e('[STT] EXCEPTION', error: e);
      return '';
    }
  }
}
