import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase_service.dart';

/// The canonical shared instance of FirebaseService used across all providers.
final firebaseServiceProvider = Provider((ref) => FirebaseService());
