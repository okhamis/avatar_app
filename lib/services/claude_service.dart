class ClaudeService {
  Future<String> generateBehavioralResponse(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    return "This is a placeholder behavioral response for prompt: $prompt";
  }

  Future<void> trainBehavior(Map<String, String> answers) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulated training
  }
}
