import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_digital_twin/services/liveavatar_service.dart';

void main() {
  test('403 + JSON code 4032 is concurrency limit', () {
    final r = http.Response(
      '{"code":4032,"data":null,"message":"Session concurrency limit reached"}',
      403,
    );
    expect(LiveAvatarService.debugIsConcurrencyLimitResponse(r), isTrue);
  });

  test('403 without 4032 is not treated as concurrency-only path', () {
    final r = http.Response('{"code":9999,"message":"other"}', 403);
    expect(LiveAvatarService.debugIsConcurrencyLimitResponse(r), isFalse);
  });

  test('200 is not concurrency', () {
    final r = http.Response('{}', 200);
    expect(LiveAvatarService.debugIsConcurrencyLimitResponse(r), isFalse);
  });
}
