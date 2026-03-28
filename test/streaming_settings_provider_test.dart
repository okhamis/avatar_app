import 'package:ai_digital_twin/providers/streaming_settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseStored maps engine names', () {
    expect(StreamingEngineNotifier.parseStored(null), isNull);
    expect(StreamingEngineNotifier.parseStored(''), isNull);
    expect(StreamingEngineNotifier.parseStored('dId'), StreamingEngine.dId);
    expect(StreamingEngineNotifier.parseStored('liveAvatar'), StreamingEngine.liveAvatar);
    expect(StreamingEngineNotifier.parseStored('heyGen'), StreamingEngine.heyGen);
    expect(StreamingEngineNotifier.parseStored('unknown'), isNull);
  });
}
