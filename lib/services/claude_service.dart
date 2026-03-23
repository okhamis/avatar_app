import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClaudeService {
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      await Future.delayed(const Duration(seconds: 1));
      return "This is a placeholder behavioral response for prompt: $prompt (Missing API Key)";
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1024,
          'system': "You are an AI performing as the precise digital twin of the user. Adhere strictly to the conversation flow and context.",
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        print("Claude API Error: ${response.statusCode}");
        return "Sorry, my neural core experienced an anomaly computing that response.";
      }
    } catch (e) {
      print("Claude API Exception: $e");
      return "Communication error with my neural core.";
    }
  }

  Future<void> trainBehavior(Map<String, String> answers) async {
    // Collect fine-tuning metadata into a context blob for future completions
    await Future.delayed(const Duration(seconds: 2));
    print("Simulated Training completed with ${answers.length} datasets.");
  }
}
