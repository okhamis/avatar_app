// Configuration file for Omar's custom test profile.

class TestProfileConfig {
  /// The local path to the face image to build the avatar.
  static const String faceImagePath = '/Users/okhamis/Documents/Omar.png';

  /// Optional: pre-cloned ElevenLabs voice ID. Set this to a real voice_id
  /// (copy from ElevenLabs dashboard or from a prior clone run) so that the
  /// test profile gets a valid voice without recording.
  /// Leave empty ('') to use the default ElevenLabs voice from AppConfig.
  static const String elevenLabsVoiceId = '';

  /// Optional: a local audio file to clone on first test-profile injection.
  /// Set to a .wav/.m4a path on disk if you want automatic voice cloning.
  /// Leave empty to skip cloning (uses elevenLabsVoiceId or default voice).
  static const String voiceSamplePath = '';

  /// Pre-defined answers to the behavioral training questions for testing.
  static const Map<String, String> behavioralAnswers = {
    // Question 1: How would you describe your communication style?
    'q1': 'I am highly direct and pragmatic, focusing on actionable outcomes, but I maintain an empathetic and collaborative tone with my team.',
    
    // Question 2: What are your core values?
    'q2': 'Integrity, relentless continuous learning, technical excellence, and building products that drive massive impact.',
    
    // Question 3: How do you typically respond when someone asks for a favor?
    'q3': 'I always evaluate my current capacity first to ensure I can deliver quality, but if it aligns with our broader goals, I am eager to help.',

    // Question 4: What are your priorities in life?
    'q4': 'My priorities are family, personal well-being, building world-class technology companies, and achieving long-term strategic impact.',

    // Question 5: How do you make decisions?
    'q5': 'I gather the necessary data comprehensively, lean on my intuition for edge cases, and ensure my team is aligned before finalizing complex decisions.',
  };
}
