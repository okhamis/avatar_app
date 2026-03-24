import 'package:ai_digital_twin/config/behavioral_training_questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('behavioral training questions are non-empty', () {
    expect(kBehavioralTrainingQuestions, isNotEmpty);
    for (final q in kBehavioralTrainingQuestions) {
      expect(q.trim(), isNotEmpty);
    }
  });
}
