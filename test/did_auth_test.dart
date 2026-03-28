import 'dart:convert';

import 'package:ai_digital_twin/utils/did_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('didBasicAuthorizationHeader encodes username:password per D-ID docs', () {
    expect(
      didBasicAuthorizationHeader('user:secret'),
      'Basic ${base64Encode(utf8.encode('user:secret'))}',
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
