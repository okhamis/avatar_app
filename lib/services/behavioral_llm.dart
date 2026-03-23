/// Shared contract for the “digital twin” text model (Gemini or Claude).
abstract interface class BehavioralLlm {
  Future<String> generateBehavioralResponse(String prompt);
  Future<String> trainBehavior(Map<String, String> answers);
}
