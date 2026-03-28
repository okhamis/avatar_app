import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

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
  static bool get useFirebaseEmulator => kReleaseMode ? false : _envBool('USE_FIREBASE_EMULATOR', false);

  static String get authEmulatorHost => _env('AUTH_EMULATOR_HOST', '127.0.0.1');
  static int get authEmulatorPort => _envInt('AUTH_EMULATOR_PORT', 9099);
  static String get firestoreEmulatorHost => _env('FIRESTORE_EMULATOR_HOST', '127.0.0.1');
  static int get firestoreEmulatorPort => _envInt('FIRESTORE_EMULATOR_PORT', 8080);

  // —— HeyGen Streaming ——
  static String get heygenStreamingNewUrl =>
      _env('HEYGEN_STREAMING_NEW_URL', 'https://api.heygen.com/v1/streaming.new');
  static String get heygenStreamingTaskUrl =>
      _env('HEYGEN_STREAMING_TASK_URL', 'https://api.heygen.com/v1/streaming.task');
  static String get heygenStreamingStopUrl =>
      _env('HEYGEN_STREAMING_STOP_URL', 'https://api.heygen.com/v1/streaming.stop');
  static String get heygenStreamingAvatarListUrl =>
      _env('HEYGEN_STREAMING_AVATAR_LIST_URL', 'https://api.heygen.com/v1/streaming/avatar.list');
  /// Fallback Interactive Avatar ID for HeyGen `streaming.new`. Used when the user has no custom photo avatar.
  static String get heygenStreamingAvatarId =>
      _env('HEYGEN_STREAMING_AVATAR_ID', _env('HEYGEN_STREAMING_AVATAR_NAME', ''));
  static String get heygenStreamingQuality => _env('HEYGEN_STREAMING_QUALITY', 'high');
  static String get heygenTaskType => _env('HEYGEN_TASK_TYPE', 'text');
  /// If true, pass stored `faceId` into `streaming.new` as `avatar_id`. Default false: photo-avatar ids are not streaming avatars.
  static bool get heygenUseStoredFaceForStreaming => _envBool('HEYGEN_USE_STORED_FACE_FOR_STREAMING', false);

  // —— HeyGen Photo Avatar ——
  static String get heygenUploadAssetUrl =>
      _env('HEYGEN_UPLOAD_ASSET_URL', 'https://upload.heygen.com/v1/asset');
  static String get heygenPhotoAvatarGroupCreateUrl =>
      _env('HEYGEN_PHOTO_AVATAR_GROUP_CREATE_URL', 'https://api.heygen.com/v2/photo_avatar/avatar_group/create');
  static String get heygenPhotoAvatarGroupAddUrl =>
      _env('HEYGEN_PHOTO_AVATAR_GROUP_ADD_URL', 'https://api.heygen.com/v2/photo_avatar/avatar_group/add');

  // —— LiveAvatar (replaces HeyGen Streaming Avatar API) ——
  static bool get liveAvatarEnabled => _envBool('LIVEAVATAR_ENABLED', false);
  static String get liveAvatarApiBase => _env('LIVEAVATAR_API_BASE', 'https://api.liveavatar.com');
  /// LITE mode avatar UUID from https://app.liveavatar.com
  static String get liveAvatarAvatarId => _env('LIVEAVATAR_AVATAR_ID', '');
  static bool get liveAvatarSandbox => _envBool('LIVEAVATAR_SANDBOX', false);
  static String get liveAvatarVideoQuality =>
      _env('LIVEAVATAR_VIDEO_QUALITY', 'high'); // very_high | high | medium | low
  static String get liveAvatarVideoEncoding =>
      _env('LIVEAVATAR_VIDEO_ENCODING', 'H264'); // VP8 | H264

  // —— D-ID Streaming ——
  static String get didApiBase => _env('DID_API_BASE', 'https://api.d-id.com');
  /// Agent ID from D-ID Studio (format: agt_xxxxxxxx). Required for Agents API.
  static String get didAgentId => _env('DID_AGENT_ID', '');
  static String get didSourceUrl => _env('DID_SOURCE_URL', ''); // e.g., s3://... or https://... image of avatar

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
  static String get geminiModel => _env('GEMINI_MODEL', 'gemini-2.5-flash');

  // —— Behavioral LLM selection ——
  static String get behaviorLlm => _env('BEHAVIOR_LLM', 'gemini').toLowerCase().trim();

  /// When true, live behavioral replies use the [behavioralChat] Cloud Function (Gemini key stays on the server).
  /// Requires Firebase Auth sign-in and a deployed function. Ignores `BEHAVIOR_LLM=claude` (server runs Gemini).
  static bool get useBackendBehaviorLlm => _envBool('USE_BACKEND_LLM', false);

  static String get cloudFunctionsRegion => _env('CLOUD_FUNCTIONS_REGION', 'us-central1');

  static bool get useFunctionsEmulator => kReleaseMode ? false : _envBool('USE_FUNCTIONS_EMULATOR', false);

  static String get functionsEmulatorHost => _env('FUNCTIONS_EMULATOR_HOST', '127.0.0.1');

  static int get functionsEmulatorPort => _envInt('FUNCTIONS_EMULATOR_PORT', 5001);

  // —— Firestore / Storage ——
  static String get firestoreUsersCollection => _env('FIRESTORE_USERS_COLLECTION', 'users');
  static String get firestoreAvatarsCollection => _env('FIRESTORE_AVATARS_COLLECTION', 'avatars');
  static String get storageAvatarsRoot => _env('STORAGE_AVATARS_ROOT', 'avatars');

  // —— Optional: fallback portrait when user has no preview (empty = icon only) ——
  static String get placeholderPortraitUrl => _env('APP_PLACEHOLDER_PORTRAIT_URL', '');

  // —— Additional Firestore collections ——
  static String get firestoreSessionsCollection => _env('FIRESTORE_SESSIONS_COLLECTION', 'sessions');
  static String get firestoreFamilyCollection => _env('FIRESTORE_FAMILY_COLLECTION', 'family_members');
  static String get firestoreCredentialsCollection => _env('FIRESTORE_CREDENTIALS_COLLECTION', 'credentials');
  static String get firestorePoliciesCollection => _env('FIRESTORE_POLICIES_COLLECTION', 'policies');
  static String get firestoreApprovalsCollection => _env('FIRESTORE_APPROVALS_COLLECTION', 'approvals');

  // —— Face upload limits ——
  static int get faceUploadMinPhotos => _envInt('FACE_UPLOAD_MIN', 5);
  static int get faceUploadMaxPhotos => _envInt('FACE_UPLOAD_MAX', 10);
}
