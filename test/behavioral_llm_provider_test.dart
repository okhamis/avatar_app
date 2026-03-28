import 'package:ai_digital_twin/config/app_config.dart';
import 'package:ai_digital_twin/providers/avatar_provider.dart';
import 'package:ai_digital_twin/services/backend_behavioral_llm_service.dart';
import 'package:ai_digital_twin/services/behavioral_llm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('behavioralLlmProvider returns correct implementation when USE_BACKEND forces backend', () {
    if (AppConfig.useBackendBehaviorLlm) {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(behavioralLlmProvider), isA<BackendBehavioralLlmService>());
      return;
    }
    final c = ProviderContainer(
      overrides: [
        behavioralLlmProvider.overrideWith((ref) => _FakeLlm()),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(behavioralLlmProvider), isA<_FakeLlm>());
  });
}

class _FakeLlm implements BehavioralLlm {
  @override
  Future<String> generateBehavioralResponse(String prompt) async => 'ok';

  @override
  Future<String> trainBehavior(Map<String, String> answers) async => 't';
}
