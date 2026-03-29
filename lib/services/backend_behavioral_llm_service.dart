import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../core/utils/app_logger.dart';
import 'behavioral_llm.dart';

/// Calls the `behavioralChat` Firebase Callable (see `functions/index.js`) so the Gemini API key is not embedded in the app.
class BackendBehavioralLlmService implements BehavioralLlm {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.cloudFunctionsRegion);

  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    if (FirebaseAuth.instance.currentUser == null) {
      AppLogger.claude.w('behavioralChat — user not signed in, returning stub');
      return 'Sign in to use the live assistant with the secure backend.';
    }

    AppLogger.claude.d('behavioralChat — calling Cloud Function promptLen=${prompt.length}');
    try {
      final callable = _functions.httpsCallable('behavioralChat');
      final result = await callable.call({'prompt': prompt});
      final raw = result.data;
      if (raw is! Map) {
        AppLogger.claude.w('behavioralChat — unexpected response type: ${raw.runtimeType}');
        return 'Sorry, the assistant returned an unexpected response.';
      }
      final text = raw['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        AppLogger.claude.i('behavioralChat OK textLen=${text.trim().length}');
        return text.trim();
      }
      AppLogger.claude.w('behavioralChat — empty text in response');
      return 'Sorry, the assistant had no reply.';
    } on FirebaseFunctionsException catch (e, st) {
      AppLogger.claude.e('behavioralChat FirebaseFunctionsException code=${e.code}', error: e.message, stackTrace: st);
      if (e.code == 'unauthenticated') {
        return 'Please sign in again to continue the conversation.';
      }
      if (e.code == 'not-found') {
        return 'Assistant backend is not deployed. Deploy Cloud Functions (behavioralChat) or set USE_BACKEND_LLM=false and use GEMINI_API_KEY locally.';
      }
      return 'The assistant is temporarily unavailable. Try again shortly.';
    } catch (e, st) {
      AppLogger.claude.e('behavioralChat error', error: e, stackTrace: st);
      return 'The assistant hit an unexpected error. Try again.';
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    AppLogger.claude.d('BackendBehavioralLlm trainBehavior placeholder: ${answers.length} answers');
    await Future.delayed(const Duration(seconds: 2));
    final id = 'behavior_${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.claude.i('BackendBehavioralLlm trainBehavior complete behaviorId=$id');
    return id;
  }
}
