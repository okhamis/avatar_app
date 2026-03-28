import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads `.env` from Flutter's asset bundle (listed in pubspec.yaml).
/// The file is gitignored and never committed — keys stay local.
Future<void> loadApplicationEnv() async {
  try {
    await dotenv.load(
      fileName: '.env',
      mergeWith: kIsWeb ? {} : Map<String, String>.from(Platform.environment),
    );
    debugPrint('dotenv: loaded .env');
  } catch (e) {
    debugPrint('dotenv: .env not found in assets ($e). Using OS env only.');
    _ensureDotenvInitialized();
  }
}

void _ensureDotenvInitialized() {
  if (dotenv.isInitialized) return;
  dotenv.loadFromString(
    envString: '',
    mergeWith: kIsWeb ? {} : Map<String, String>.from(Platform.environment),
    isOptional: true,
  );
  debugPrint('dotenv: initialized empty + OS env (fallback)');
}
