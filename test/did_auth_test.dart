import 'package:ai_digital_twin/utils/did_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('didBasicAuthorizationHeader passes key as-is per D-ID Studio format', () {
    expect(
      didBasicAuthorizationHeader('user:secret'),
      'Basic user:secret',
    );
  });

  test('didBasicAuthorizationHeader passes through token without colon', () {
    expect(didBasicAuthorizationHeader('YWJjZGVm'), 'Basic YWJjZGVm');
  });

  test('null and empty return null', () {
    expect(didBasicAuthorizationHeader(null), isNull);
    expect(didBasicAuthorizationHeader(''), isNull);
    expect(didBasicAuthorizationHeader('   '), isNull);
  });
}
