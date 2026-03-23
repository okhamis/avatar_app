import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      final useEmulator = const bool.fromEnvironment(
        'USE_FIREBASE_EMULATOR',
        defaultValue: true,
      );
      if (useEmulator) {
        await _connectToEmulators();
      }
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    const ProviderScope(
      child: PresntApp(),
    ),
  );
}

Future<void> _connectToEmulators() async {
  const authHost = String.fromEnvironment('AUTH_EMULATOR_HOST', defaultValue: '127.0.0.1');
  const authPort = int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);
  const firestoreHost = String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '127.0.0.1');
  const firestorePort = int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);

  try {
    await FirebaseAuth.instance.useAuthEmulator(authHost, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(firestoreHost, firestorePort);
    debugPrint('Connected to Firebase emulators (Auth: $authHost:$authPort, Firestore: $firestoreHost:$firestorePort)');
  } catch (e) {
    debugPrint('Firebase emulator connection failed: $e');
  }
}
