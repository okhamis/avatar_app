import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';

  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['CLAUDE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('placeholder')) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 'Placeholder response: I am representing the user according to their trained communication style.';
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-latest',
          'max_tokens': 300,
          'system':
              'You are a digital twin assistant for the user. Maintain safe boundaries, never reveal raw credentials, and ask for approval for sensitive actions.',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Claude error status: ${response.statusCode}');
        return 'I could not reach my behavioral model right now.';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map<String, dynamic> && first['text'] is String) {
          return first['text'] as String;
        }
      }
      return 'I received an empty response from the behavioral model.';
    } catch (e) {
      debugPrint('Claude request failed: $e');
      return 'Behavioral model communication error.';
    }
  }

  Future<void> trainBehavior(Map<String, String> answers) async {
    // Placeholder for a future pipeline that stores prompts/profile traits.
    await Future.delayed(const Duration(milliseconds: 900));
    debugPrint('Behavior profile snapshot captured: ${answers.length} answers.');
  }
}
