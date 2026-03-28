import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StreamingEngine { liveAvatar, dId, heyGen }

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
