import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate(String reason) async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // In release mode, fail closed when biometrics are unavailable.
        // In debug mode, allow through for development convenience.
        if (kDebugMode) {
          debugPrint('BiometricService: device does not support biometrics, allowing in debug mode.');
          return true;
        }
        return false;
      }

      return await auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService PlatformException: $e');
      return false;
    }
  }
}
