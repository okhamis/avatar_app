import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/llm_prompts.dart';
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
      await Future.delayed(const Duration(seconds: 1));
      return "I am your Presnt avatar. I received your message and I am processing it on your behalf. (Configure GEMINI_API_KEY to enable live responses.)";
    }

    // Common mistake: "gen-lang-client-..." is not a Gemini API key (use AI Studio key, usually starts with AIza).
    if (apiKey.startsWith('gen-lang-client-')) {
      debugPrint(
        'GEMINI_API_KEY looks like a client id, not an API key. Use https://aistudio.google.com/app/apikey',
      );
      return "GEMINI_API_KEY in .env is not a valid Gemini API key (\"gen-lang-client-...\" is the wrong kind of credential). Open https://aistudio.google.com/app/apikey , create an API key, and paste the value that typically starts with \"AIza\".";
    }

    if (!apiKey.startsWith('AIza')) {
      debugPrint(
        'GEMINI_API_KEY does not start with AIza; if the API fails, create a key at https://aistudio.google.com/app/apikey',
      );
    }

    try {
      final model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(kGeminiDigitalTwinSystemInstruction),
      );

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      return response.text ?? "Sorry, no response generated from the Gemini neural core.";
    } catch (e) {
      debugPrint("Gemini API Exception: $e");
      final msg = e.toString();
      final lower = msg.toLowerCase();
      final looksLikeKeyProblem = lower.contains('api key') &&
          (lower.contains('invalid') ||
              lower.contains('not valid') ||
              lower.contains('permission denied') ||
              lower.contains('api_key_invalid'));
      if (looksLikeKeyProblem) {
        return "Invalid or unauthorized Gemini API key. Create a key at https://aistudio.google.com/app/apikey , set GEMINI_API_KEY in .env (no quotes), full restart the app.";
      }
      return "Communication error with my Gemini core: ${msg.length > 200 ? msg.substring(0, 200) : msg}";
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    // Collect fine-tuning metadata into a context blob for future Gemini context windows
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Simulated Training completed with ${answers.length} datasets using Gemini framework.");
    return "behavior_${DateTime.now().millisecondsSinceEpoch}";
  }
}
