import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/app_logger.dart';

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
    AppLogger.streaming.d('AvatarModeNotifier init — loading stored mode, default=custom');
    _loadAndUpdate();
    return AvatarMode.custom;
  }

  void _loadAndUpdate() {
    _storage.read(key: _key).then((val) {
      AppLogger.streaming.d('AvatarMode loaded from storage: ${val ?? "null (using default)"}');
      if (val == 'studio') {
        state = AvatarMode.studio;
      } else if (val == 'custom') {
        state = AvatarMode.custom;
      }
    }).catchError((e) {
      AppLogger.streaming.w('AvatarMode storage read failed, using default', error: e);
    });
  }

  Future<void> setMode(AvatarMode mode) async {
    AppLogger.streaming.i('AvatarMode changed to ${mode.name}');
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
    AppLogger.streaming.d('StreamingEngineNotifier init — loading stored engine, default=dId');
    _loadAndUpdate();
    return StreamingEngine.dId;
  }

  void _loadAndUpdate() {
    _storage.read(key: _key).then((val) {
      final parsed = parseStored(val);
      AppLogger.streaming.d('StreamingEngine loaded from storage: ${parsed?.name ?? "null (using default)"}');
      if (parsed != null) {
        state = parsed;
      }
    }).catchError((e) {
      AppLogger.streaming.w('StreamingEngine storage read failed, using default', error: e);
    });
  }

  Future<void> setEngine(StreamingEngine engine) async {
    AppLogger.streaming.i('StreamingEngine changed to ${engine.name}');
    state = engine;
    await _storage.write(key: _key, value: engine.name);
  }
}

final testProfileEnabledProvider = NotifierProvider<TestProfileEnabledNotifier, bool>(TestProfileEnabledNotifier.new);

class TestProfileEnabledNotifier extends Notifier<bool> {
  static const _key = 'use_test_profile';
  final _storage = const FlutterSecureStorage();

  @override
  bool build() {
    AppLogger.streaming.d('TestProfileEnabledNotifier init — loading stored value, default=true');
    _loadAndUpdate();
    return true;
  }

  void _loadAndUpdate() {
    _storage.read(key: _key).then((val) {
      AppLogger.streaming.d('TestProfileEnabled loaded from storage: ${val ?? "null (using default)"}');
      if (val == 'true') {
        state = true;
      } else if (val == 'false') {
        state = false;
      }
    }).catchError((e) {
      AppLogger.streaming.w('TestProfileEnabled storage read failed, using default', error: e);
    });
  }

  Future<void> setEnabled(bool enabled) async {
    AppLogger.streaming.i('TestProfileEnabled changed to $enabled');
    state = enabled;
    await _storage.write(key: _key, value: enabled.toString());
  }
}
