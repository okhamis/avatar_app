import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// How the avatar is sourced.
///   studio  — use a pre-built D-ID Studio agent (works now).
///   custom  — full pipeline: user photo → D-ID avatar, user voice → ElevenLabs clone.
enum AvatarMode { studio, custom }

enum StreamingEngine { liveAvatar, dId, heyGen }

final avatarModeProvider = NotifierProvider<AvatarModeNotifier, AvatarMode>(AvatarModeNotifier.new);

class AvatarModeNotifier extends Notifier<AvatarMode> {
  static const _key = 'avatar_mode';
  final _storage = const FlutterSecureStorage();

  @override
  AvatarMode build() {
    _load();
    return AvatarMode.studio;
  }

  Future<void> _load() async {
    final val = await _storage.read(key: _key);
    if (val == 'custom') state = AvatarMode.custom;
  }

  Future<void> setMode(AvatarMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }
}

final streamingEngineProvider = NotifierProvider<StreamingEngineNotifier, StreamingEngine>(StreamingEngineNotifier.new);

class StreamingEngineNotifier extends Notifier<StreamingEngine> {
  static const _key = 'selected_streaming_engine';
  final _storage = const FlutterSecureStorage();

  static StreamingEngine? parseStored(String? val) {
    if (val == null || val.isEmpty) return null;
    switch (val) {
      case 'dId':
        return StreamingEngine.dId;
      case 'heyGen':
        return StreamingEngine.heyGen;
      case 'liveAvatar':
        return StreamingEngine.liveAvatar;
      default:
        return null;
    }
  }

  @override
  StreamingEngine build() {
    _load();
    return StreamingEngine.dId;
  }

  Future<void> _load() async {
    final val = await _storage.read(key: _key);
    final parsed = parseStored(val);
    if (parsed != null) {
      state = parsed;
    }
  }

  Future<void> setEngine(StreamingEngine engine) async {
    state = engine;
    await _storage.write(key: _key, value: engine.name);
  }
}
