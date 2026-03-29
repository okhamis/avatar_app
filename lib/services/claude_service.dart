import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/llm_prompts.dart';
import '../core/utils/app_logger.dart';
import 'behavioral_llm.dart';

class ClaudeService implements BehavioralLlm {
  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? dotenv.env['CLAUDE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('your_')) {
      AppLogger.claude.w('No ANTHROPIC_API_KEY — returning stub response');
      await Future.delayed(const Duration(milliseconds: 800));
      return 'I am your Presnt avatar. (Add a real CLAUDE_API_KEY in .env to enable live Claude replies.)';
    }

    final model = dotenv.env['CLAUDE_MODEL']?.trim();
    final modelId = (model == null || model.isEmpty) ? AppConfig.claudeDefaultModel : model;

    AppLogger.claude.i('generateBehavioralResponse — model=$modelId promptLen=${prompt.length}');
    AppLogger.claude.d('Request: maxTokens=${AppConfig.claudeMaxTokens} promptPreview="${prompt.length > 80 ? prompt.substring(0, 80) : prompt}"');

    try {
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
        AppLogger.claude.w('API error HTTP ${response.statusCode}', error: response.body.length > 300 ? response.body.substring(0, 300) : response.body);
        return 'I could not reach my behavioral model right now.';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map<String, dynamic> && first['text'] is String) {
          final text = first['text'] as String;
          AppLogger.claude.i('generateBehavioralResponse OK — responseLen=${text.length}');
          return text;
        }
      }
      AppLogger.claude.w('generateBehavioralResponse: empty/unexpected response shape');
      return 'I received an empty response from the behavioral model.';
    } catch (e) {
      AppLogger.claude.e('Request failed', error: e);
      return 'Behavioral model communication error.';
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    AppLogger.claude.d('trainBehavior snapshot: ${answers.length} answers');
    await Future.delayed(const Duration(milliseconds: 900));
    final id = 'behavior_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.claude.i('trainBehavior complete behaviorId=$id');
    return id;
  }
}
