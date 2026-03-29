import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/app_config.dart';
import '../config/llm_prompts.dart';
import '../core/utils/app_logger.dart';
import 'behavioral_llm.dart';

class GeminiService implements BehavioralLlm {
  static String? _geminiKeyFromEnv() {
    var raw = dotenv.env['GEMINI_API_KEY']?.trim();
    if (raw == null || raw.isEmpty) return null;
    // Strip optional surrounding quotes from .env
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
      return "I am your Presnt avatar. I received your message and I am processing it on your behalf. (Configure GEMINI_API_KEY to enable live responses.)";
    }

    // Common mistake: "gen-lang-client-..." is not a Gemini API key
    if (apiKey.startsWith('gen-lang-client-')) {
      AppLogger.gemini.w('GEMINI_API_KEY looks like a client ID — use AIza key from AI Studio');
      return "GEMINI_API_KEY in .env is not a valid Gemini API key (\"gen-lang-client-...\" is the wrong kind of credential). Open https://aistudio.google.com/app/apikey , create an API key, and paste the value that typically starts with \"AIza\".";
    }

    if (!apiKey.startsWith('AIza')) {
      AppLogger.gemini.w('GEMINI_API_KEY format unexpected — expected AIza prefix; if API fails create key at AI Studio');
    }

    AppLogger.gemini.i('generateBehavioralResponse — model=${AppConfig.geminiModel} promptLen=${prompt.length}');

    try {
      final model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(kGeminiDigitalTwinSystemInstruction),
      );

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      final text = response.text ?? "Sorry, no response generated from the Gemini neural core.";
      AppLogger.gemini.i('generateBehavioralResponse OK — responseLen=${text.length}');
      return text;
    } catch (e) {
      AppLogger.gemini.e('API exception', error: e);
      final msg = e.toString();
      final lower = msg.toLowerCase();
      final looksLikeKeyProblem = lower.contains('api key') &&
          (lower.contains('invalid') ||
              lower.contains('not valid') ||
              lower.contains('permission denied') ||
              lower.contains('api_key_invalid'));
      if (looksLikeKeyProblem) {
        AppLogger.gemini.e('Invalid/unauthorized Gemini API key — check AI Studio');
        return "Invalid or unauthorized Gemini API key. Create a key at https://aistudio.google.com/app/apikey , set GEMINI_API_KEY in .env (no quotes), full restart the app.";
      }
      return "Communication error with my Gemini core: ${msg.length > 200 ? msg.substring(0, 200) : msg}";
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    AppLogger.gemini.d('trainBehavior placeholder: ${answers.length} answers');
    await Future.delayed(const Duration(seconds: 2));
    final id = "behavior_${DateTime.now().millisecondsSinceEpoch}";
    AppLogger.gemini.i('trainBehavior complete behaviorId=$id');
    return id;
  }
}
