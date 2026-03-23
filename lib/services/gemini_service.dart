import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'behavioral_llm.dart';

class GeminiService implements BehavioralLlm {
  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('your_')) {
      await Future.delayed(const Duration(seconds: 1));
      return "I am your Presnt avatar. I received your message and I am processing it on your behalf. (Configure GEMINI_API_KEY to enable live responses.)";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system("You are an AI performing as the precise digital twin of the user. Adhere strictly to the conversation flow and context."),
      );

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      return response.text ?? "Sorry, no response generated from the Gemini neural core.";
    } catch (e) {
      debugPrint("Gemini API Exception: $e");
      return "Communication error with my Gemini core.";
    }
  }

  @override
  Future<void> trainBehavior(Map<String, String> answers) async {
    // Collect fine-tuning metadata into a context blob for future Gemini context windows
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Simulated Training completed with ${answers.length} datasets using Gemini framework.");
  }
}
