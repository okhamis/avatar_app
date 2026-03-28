import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bootstrap/load_env.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'app.dart';

final class AppProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final p = context.provider;
    debugPrint('Provider [${p.name ?? p.runtimeType}] threw: $error\n$stackTrace');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadApplicationEnv();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Use memory cache to avoid Firestore LevelDB LOCK file crashes on macOS
    // when multiple app instances run simultaneously (common during development).
    // Persistent cache can be re-enabled for production if offline support is needed.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    if (kDebugMode && AppConfig.useFirebaseEmulator) {
      await _connectToEmulators();
    }
    if (kDebugMode && AppConfig.useFunctionsEmulator) {
      FirebaseFunctions.instanceFor(region: AppConfig.cloudFunctionsRegion).useFunctionsEmulator(
        AppConfig.functionsEmulatorHost,
        AppConfig.functionsEmulatorPort,
      );
      debugPrint(
        'Cloud Functions emulator: ${AppConfig.functionsEmulatorHost}:${AppConfig.functionsEmulatorPort} (${AppConfig.cloudFunctionsRegion})',
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const PresntApp(),
    ),
  );
}

Future<void> _connectToEmulators() async {
  final authHost = AppConfig.authEmulatorHost;
  final authPort = AppConfig.authEmulatorPort;
  final firestoreHost = AppConfig.firestoreEmulatorHost;
  final firestorePort = AppConfig.firestoreEmulatorPort;

  try {
    await FirebaseAuth.instance.useAuthEmulator(authHost, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(firestoreHost, firestorePort);
    debugPrint('Connected to Firebase emulators (Auth: $authHost:$authPort, Firestore: $firestoreHost:$firestorePort)');
  } catch (e) {
    debugPrint('Firebase emulator connection failed: $e');
  }
}
