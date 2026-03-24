import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/llm_prompts.dart';
import 'behavioral_llm.dart';

class ClaudeService implements BehavioralLlm {
  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['CLAUDE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('your_')) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 'I am your Presnt avatar. (Add a real CLAUDE_API_KEY in .env to enable live Claude replies.)';
    }

    try {
      final model = dotenv.env['CLAUDE_MODEL']?.trim();
      final modelId = (model == null || model.isEmpty) ? AppConfig.claudeDefaultModel : model;

      final response = await http.post(
        Uri.parse(AppConfig.anthropicMessagesUrl),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': AppConfig.anthropicVersion,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': modelId,
          'max_tokens': AppConfig.claudeMaxTokens,
          'system': kClaudeDigitalTwinSystemPrompt,
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

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    // Placeholder for a future pipeline that stores prompts/profile traits.
    await Future.delayed(const Duration(milliseconds: 900));
    debugPrint('Behavior profile snapshot captured: ${answers.length} answers.');
    return 'behavior_${DateTime.now().millisecondsSinceEpoch}';
  }
}
