import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'behavioral_llm.dart';

/// Calls the `behavioralChat` Firebase Callable (see `functions/index.js`) so the Gemini API key is not embedded in the app.
class BackendBehavioralLlmService implements BehavioralLlm {
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.cloudFunctionsRegion);

  @override
  Future<String> generateBehavioralResponse(String prompt) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return 'Sign in to use the live assistant with the secure backend.';
    }
    try {
      final callable = _functions.httpsCallable('behavioralChat');
      final result = await callable.call({'prompt': prompt});
      final raw = result.data;
      if (raw is! Map) {
        return 'Sorry, the assistant returned an unexpected response.';
      }
      final text = raw['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      return 'Sorry, the assistant had no reply.';
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('behavioralChat FirebaseFunctionsException [${e.code}]: ${e.message}\n$st');
      if (e.code == 'unauthenticated') {
        return 'Please sign in again to continue the conversation.';
      }
      if (e.code == 'not-found') {
        return 'Assistant backend is not deployed. Deploy Cloud Functions (behavioralChat) or set USE_BACKEND_LLM=false and use GEMINI_API_KEY locally.';
      }
      return 'The assistant is temporarily unavailable. Try again shortly.';
    } catch (e, st) {
      debugPrint('behavioralChat error: $e\n$st');
      return 'The assistant hit an unexpected error. Try again.';
    }
  }

  @override
  Future<String> trainBehavior(Map<String, String> answers) async {
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('BackendBehavioralLlm: trainBehavior placeholder (${answers.length} answers).');
    return 'behavior_${DateTime.now().millisecondsSinceEpoch}';
  }
}
