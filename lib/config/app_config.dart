import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central runtime configuration. Values may be overridden via `.env` (see `.env.example`).
abstract final class AppConfig {
  static String _env(String key, String fallback) {
    try {
      final v = dotenv.env[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return fallback;
  }

  static bool _envBool(String key, bool fallback) {
    final v = _env(key, '').toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
    return fallback;
  }

  static int _envInt(String key, int fallback) {
    final raw = _env(key, '');
    if (raw.isEmpty) return fallback;
    return int.tryParse(raw) ?? fallback;
  }

  static double _envDouble(String key, double fallback) {
    final raw = _env(key, '');
    if (raw.isEmpty) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  // —— Firebase emulator (debug; compile-time flags still preferred in main.dart) ——
  static bool get useFirebaseEmulator => _envBool('USE_FIREBASE_EMULATOR', true);

  static String get authEmulatorHost => _env('AUTH_EMULATOR_HOST', '127.0.0.1');
  static int get authEmulatorPort => _envInt('AUTH_EMULATOR_PORT', 9099);
  static String get firestoreEmulatorHost => _env('FIRESTORE_EMULATOR_HOST', '127.0.0.1');
  static int get firestoreEmulatorPort => _envInt('FIRESTORE_EMULATOR_PORT', 8080);

  // —— HeyGen ——
  static String get heygenStreamingNewUrl =>
      _env('HEYGEN_STREAMING_NEW_URL', 'https://api.heygen.com/v1/streaming.new');
  static String get heygenStreamingTaskUrl =>
      _env('HEYGEN_STREAMING_TASK_URL', 'https://api.heygen.com/v1/streaming.task');
  static String get heygenStreamingStopUrl =>
      _env('HEYGEN_STREAMING_STOP_URL', 'https://api.heygen.com/v1/streaming.stop');
  static String get heygenStreamingAvatarName => _env('HEYGEN_STREAMING_AVATAR_NAME', '');
  static String get heygenStreamingQuality => _env('HEYGEN_STREAMING_QUALITY', 'high');
  static String get heygenTaskType => _env('HEYGEN_TASK_TYPE', 'text');

  // —— ElevenLabs ——
  static String get elevenLabsTtsBaseUrl =>
      _env('ELEVENLABS_TTS_BASE_URL', 'https://api.elevenlabs.io/v1/text-to-speech');
  static String get elevenLabsVoiceId => _env('ELEVENLABS_VOICE_ID', '21m00Tcm4TlvDq8ikWAM');
  static String get elevenLabsModelId => _env('ELEVENLABS_MODEL_ID', 'eleven_monolingual_v1');
  static double get elevenLabsStability => _envDouble('ELEVENLABS_STABILITY', 0.5);
  static double get elevenLabsSimilarityBoost => _envDouble('ELEVENLABS_SIMILARITY_BOOST', 0.5);

  // —— Anthropic ——
  static String get anthropicMessagesUrl =>
      _env('ANTHROPIC_MESSAGES_URL', 'https://api.anthropic.com/v1/messages');
  static String get anthropicVersion => _env('ANTHROPIC_VERSION', '2023-06-01');
  static String get claudeDefaultModel => _env('CLAUDE_MODEL', 'claude-sonnet-4-20250514');
  static int get claudeMaxTokens => _envInt('CLAUDE_MAX_TOKENS', 300);

  // —— Google Gemini ——
  static String get geminiModel => _env('GEMINI_MODEL', 'gemini-1.5-flash');

  // —— Behavioral LLM selection ——
  static String get behaviorLlm => _env('BEHAVIOR_LLM', 'gemini').toLowerCase().trim();

  // —— Firestore / Storage ——
  static String get firestoreUsersCollection => _env('FIRESTORE_USERS_COLLECTION', 'users');
  static String get firestoreAvatarsCollection => _env('FIRESTORE_AVATARS_COLLECTION', 'avatars');
  static String get storageAvatarsRoot => _env('STORAGE_AVATARS_ROOT', 'avatars');

  // —— Optional: fallback portrait when user has no preview (empty = icon only) ——
  static String get placeholderPortraitUrl => _env('APP_PLACEHOLDER_PORTRAIT_URL', '');

  // —— Face upload limits ——
  static int get faceUploadMinPhotos => _envInt('FACE_UPLOAD_MIN', 5);
  static int get faceUploadMaxPhotos => _envInt('FACE_UPLOAD_MAX', 10);
}
