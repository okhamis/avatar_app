import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LogEntry — immutable snapshot of a single log event for in-app display
// ─────────────────────────────────────────────────────────────────────────────

class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String toPlainText() {
    final ts = timestamp.toIso8601String();
    final lvl = level.name.toUpperCase().padRight(7);
    return '[$ts][$lvl] $message';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BufferOutput — circular in-memory buffer exposed as a broadcast Stream
// ─────────────────────────────────────────────────────────────────────────────

class _BufferOutput extends LogOutput {
  static const int _kCapacity = 500;

  final _buffer = ListQueue<LogEntry>(_kCapacity);
  final _controller = StreamController<List<LogEntry>>.broadcast();

  Stream<List<LogEntry>> get stream => _controller.stream;
  List<LogEntry> get snapshot => List.unmodifiable(_buffer);

  @override
  void output(OutputEvent event) {
    // Use raw origin fields — avoids PrettyPrinter box-drawing noise (┌──, │, └──)
    final msg = StringBuffer();
    msg.write(event.origin.message?.toString() ?? '');
    if (event.origin.error != null) {
      msg.write('\n  error: ${event.origin.error}');
    }
    if (event.origin.stackTrace != null) {
      msg.write('\n  stackTrace: ${event.origin.stackTrace}');
    }
    final entry = LogEntry(
      timestamp: event.origin.time,
      level: event.origin.level,
      message: msg.toString(),
    );
    if (_buffer.length >= _kCapacity) _buffer.removeFirst();
    _buffer.addLast(entry);
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_buffer));
    }
  }

  void clear() {
    _buffer.clear();
    if (!_controller.isClosed) _controller.add(const []);
  }

  String export() => _buffer.map((e) => e.toPlainText()).join('\n');

  @override
  Future<void> destroy() async {
    await _controller.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FileOutput — persists logs to a date-stamped file in Documents/logs/
// ─────────────────────────────────────────────────────────────────────────────

class _FileOutput extends LogOutput {
  IOSink? _sink;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      await logDir.create(recursive: true);
      final today = DateTime.now().toIso8601String().split('T').first;
      final file = File('${logDir.path}/app_$today.log');
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('[AppLogger] FileOutput init failed: $e');
    }
  }

  @override
  void output(OutputEvent event) {
    _init();
    final line = '[${DateTime.now().toIso8601String()}] ${event.lines.join('\n')}';
    _sink?.writeln(line);
  }

  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLogger — central singleton
// ─────────────────────────────────────────────────────────────────────────────

/// Central application logger.
///
/// Named loggers per component:
///   [AppLogger.auth]         — AuthProvider, auth FirebaseService calls
///   [AppLogger.avatar]       — AvatarProvider
///   [AppLogger.did]          — DidService, DidWebrtcVideo
///   [AppLogger.elevenlabs]   — ElevenLabsService
///   [AppLogger.gemini]       — GeminiService
///   [AppLogger.claude]       — ClaudeService, BackendBehavioralLlmService
///   [AppLogger.heygen]       — HeyGenService
///   [AppLogger.liveAvatar]   — LiveAvatarService
///   [AppLogger.firebase]     — FirebaseService (Firestore/Storage)
///   [AppLogger.session]      — SessionProvider
///   [AppLogger.streaming]    — StreamingSettingsProvider
///   [AppLogger.conversation] — LiveConversationScreen
///   [AppLogger.main]         — main.dart / bootstrap
///
/// Log level policy:
///   t / trace   — raw HTTP bodies, PCM chunks, fine-grained step data
///   d / debug   — method entry with params, state before transitions
///   i / info    — successful operations, state transitions, timings
///   w / warning — missing API keys, 4xx HTTP, fallback paths, non-fatal errors
///   e / error   — exceptions, 5xx HTTP, unrecoverable failures
///   f / fatal   — impossible states
class AppLogger {
  AppLogger._();

  static final _fileOutput   = _FileOutput();
  static final _bufferOutput = _BufferOutput();

  static Logger _make(String tag) {
    final outputs = <LogOutput>[
      if (kDebugMode) ConsoleOutput(),
      _fileOutput,
      _bufferOutput,
    ];
    return Logger(
      printer: kDebugMode
          ? PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            )
          : SimplePrinter(colors: false, printTime: true),
      output: MultiOutput(outputs),
      level: kDebugMode ? Level.trace : Level.warning,
      filter: ProductionFilter(),
    );
  }

  static final auth         = _make('auth');
  static final avatar       = _make('avatar');
  static final did          = _make('did');
  static final elevenlabs   = _make('elevenlabs');
  static final gemini       = _make('gemini');
  static final claude       = _make('claude');
  static final heygen       = _make('heygen');
  static final liveAvatar   = _make('liveAvatar');
  static final firebase     = _make('firebase');
  static final session      = _make('session');
  static final streaming    = _make('streaming');
  static final conversation = _make('conversation');
  static final main         = _make('main');

  // ── In-memory buffer public API ──────────────────────────────────────────

  /// Live stream of all buffered log entries (last 500). Subscribe to
  /// receive the full current list on every new log event.
  static Stream<List<LogEntry>> get logStream => _bufferOutput.stream;

  /// Current snapshot of buffered entries — useful for the initial render.
  static List<LogEntry> get logSnapshot => _bufferOutput.snapshot;

  /// Clears the in-memory buffer and emits an empty list.
  static void clearLogs() => _bufferOutput.clear();

  /// Exports all buffered entries as plain text for clipboard/share.
  static String exportLogs() => _bufferOutput.export();

  // ── Maintenance ──────────────────────────────────────────────────────────

  /// Deletes log files older than [keepDays] days. Call once at startup.
  static Future<void> cleanOldLogs({int keepDays = 7}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!await logDir.exists()) return;
      final cutoff = DateTime.now().subtract(Duration(days: keepDays));
      await for (final entity in logDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
            main.d('Deleted old log file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      main.w('Log cleanup failed', error: e);
    }
  }

  /// Flush file sink on app shutdown.
  static Future<void> dispose() => _fileOutput.dispose();
}
