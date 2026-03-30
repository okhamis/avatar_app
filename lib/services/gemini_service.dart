import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/llm_prompts.dart';
import '../core/utils/app_logger.dart';
import 'behavioral_llm.dart';

class GeminiService implements BehavioralLlm {
  static String? _geminiKeyFromEnv() {
    var raw = dotenv.env['GEMINI_API_KEY']?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.length >= 2 &&
        ((raw.startsWith('"') && raw.endsWith('"')) ||
            (raw.startsWith("'") && raw.endsWith("'")))) {
      raw = raw.substring(1, raw.length - 1).trim();
    }
    return raw.isEmpty ? null : raw;
  }

  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = _geminiKeyFromEnv();

    if (apiKey == null || apiKey.startsWith('your_')) {
      AppLogger.gemini.w('GEMINI_API_KEY missing — returning stub response');
      await Future.delayed(const Duration(seconds: 1));
      return 'I am your Presnt avatar. Configure GEMINI_API_KEY to enable live responses.';
    }

    final model = AppConfig.geminiModel;
    AppLogger.gemini.i('generateBehavioralResponse — model=$model promptLen=${prompt.length}');

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final body = jsonEncode({
        'system_instruction': {
          'parts': [{'text': kGeminiDigitalTwinSystemInstruction}]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [{'text': prompt}]
          }
        ],
        'tools': [
          {'google_search': {}}
        ],
      });

      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
      AppLogger.gemini.d('HTTP ${res.statusCode}');

      if (res.statusCode != 200) {
        AppLogger.gemini.w('API error ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
        return 'I could not reach my knowledge base right now.';
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null) {
          final text = parts
              .where((p) => p is Map && p['text'] != null)
              .map((p) => p['text'] as String)
              .join(' ');
          if (text.isNotEmpty) {
            AppLogger.gemini.i('generateBehavioralResponse OK — responseLen=${text.length}');
            return text;
          }
        }
      }

      AppLogger.gemini.w('Empty response from Gemini');
      return 'I received an empty response.';
    } catch (e) {
      AppLogger.gemini.e('Request failed', error: e);
      return 'Communication error: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}';
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    AppLogger.gemini.d('trainBehavior placeholder: ${answers.length} answers');
    await Future.delayed(const Duration(seconds: 2));
    final id = 'behavior_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.gemini.i('trainBehavior complete behaviorId=$id');
    return id;
  }
}
