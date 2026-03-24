import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode && AppConfig.useFirebaseEmulator) {
      await _connectToEmulators();
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
