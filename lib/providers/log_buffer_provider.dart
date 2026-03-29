import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_logger.dart';

export '../core/utils/app_logger.dart' show LogEntry;

/// Streams the full current list of [LogEntry] objects as new logs arrive.
final logBufferProvider = StreamProvider<List<LogEntry>>((ref) {
  return AppLogger.logStream;
});
