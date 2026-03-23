import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      await Future.delayed(const Duration(seconds: 1));
      return "This is a placeholder behavioral response for prompt: $prompt (Missing Google Gemini API Key)";
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
      print("Gemini API Exception: $e");
      return "Communication error with my Gemini core.";
    }
  }

  Future<void> trainBehavior(Map<String, String> answers) async {
    // Collect fine-tuning metadata into a context blob for future Gemini context windows
    await Future.delayed(const Duration(seconds: 2));
    print("Simulated Training completed with ${answers.length} datasets using Gemini framework.");
  }
}
