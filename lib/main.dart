import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Placeholder for Firebase initialization and other async tasks
  
  runApp(
    const ProviderScope(
      child: PresntApp(),
    ),
  );
}
