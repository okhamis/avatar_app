import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../providers/log_buffer_provider.dart';
import '../../core/utils/app_logger.dart';
import '../../theme/presnt_tokens.dart';

class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({super.key});

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  Level? _activeFilter;
  bool _autoScroll = true;

  static const _filterLevels = <Level?>[
    null,
    Level.debug,
    Level.info,
    Level.warning,
    Level.error,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final atBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 80;
      if (_autoScroll != atBottom) setState(() => _autoScroll = atBottom);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_autoScroll || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyAll() {
    final text = AppLogger.exportLogs();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to copy')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PresntTokens.surfaceContainerHigh,
        title: const Text('Clear logs?', style: TextStyle(color: PresntTokens.onSurface)),
        content: const Text(
          'This clears the in-memory log buffer.',
          style: TextStyle(color: PresntTokens.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PresntTokens.outline)),
          ),
          TextButton(
            onPressed: () {
              AppLogger.clearLogs();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: PresntTokens.error)),
          ),
        ],
      ),
    );
  }

  static Color _colorForLevel(Level? level) => switch (level) {
        Level.trace   => const Color(0xFF757575),
        Level.debug   => const Color(0xFF9E9E9E),
        Level.info    => PresntTokens.secondary,
        Level.warning => const Color(0xFFFFB74D),
        Level.error   => PresntTokens.error,
        Level.fatal   => PresntTokens.primary,
        _             => PresntTokens.onSurfaceVariant,
      };

  static String _levelLabel(Level? level) => switch (level) {
        Level.trace   => 'TRACE',
        Level.debug   => 'DEBUG',
        Level.info    => 'INFO',
        Level.warning => 'WARN',
        Level.error   => 'ERROR',
        Level.fatal   => 'FATAL',
        _             => 'ALL',
      };

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(logBufferProvider);

    return Scaffold(
      backgroundColor: PresntTokens.background,
      appBar: AppBar(
        backgroundColor: PresntTokens.surfaceContainerLow,
        foregroundColor: PresntTokens.onSurface,
        title: const Text(
          'App Logs',
          style: TextStyle(
            color: PresntTokens.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _autoScroll ? 'Auto-scroll on' : 'Auto-scroll off',
            icon: Icon(
              Icons.vertical_align_bottom_rounded,
              color: _autoScroll ? PresntTokens.secondary : PresntTokens.outline,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: PresntTokens.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: const TextStyle(color: PresntTokens.outline, fontSize: 14),
                filled: true,
                fillColor: PresntTokens.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.search_rounded, color: PresntTokens.outline, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: PresntTokens.outline, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Level filter chips ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterLevels.map((level) {
                  final isSelected = _activeFilter == level;
                  final color = _colorForLevel(level);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeFilter = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withAlpha(45) : PresntTokens.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : PresntTokens.outlineVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          _levelLabel(level),
                          style: TextStyle(
                            color: isSelected ? color : PresntTokens.outline,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(color: PresntTokens.outlineVariant, height: 1),

          // ── Log list ───────────────────────────────────────────────────
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(
                child: Text(
                  'Waiting for logs...',
                  style: TextStyle(color: PresntTokens.outline, fontSize: 14),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: PresntTokens.error, fontSize: 14),
                ),
              ),
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_activeFilter != null && e.level != _activeFilter) return false;
                  if (_searchQuery.isNotEmpty &&
                      !e.message.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
                  return true;
                }).toList();

                _scrollToBottom();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      entries.isEmpty ? 'No logs yet.' : 'No matches for "$_searchQuery".',
                      style: const TextStyle(color: PresntTokens.outline, fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    color: PresntTokens.outlineVariant,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) => _LogEntryTile(entry: filtered[index]),
                );
              },
            ),
          ),

          // ── Bottom action bar: Copy + Clear ─────────────────────────────
          Container(
            color: PresntTokens.surfaceContainerLow,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyAll,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PresntTokens.secondary,
                      side: const BorderSide(color: PresntTokens.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear Logs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PresntTokens.error,
                      side: const BorderSide(color: PresntTokens.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  const _LogEntryTile({required this.entry});

  static Color _colorForLevel(Level level) => switch (level) {
        Level.trace   => const Color(0xFF757575),
        Level.debug   => const Color(0xFF9E9E9E),
        Level.info    => PresntTokens.secondary,
        Level.warning => const Color(0xFFFFB74D),
        Level.error   => PresntTokens.error,
        Level.fatal   => PresntTokens.primary,
        _             => PresntTokens.onSurfaceVariant,
      };

  static String _levelWord(Level level) => switch (level) {
        Level.trace   => 'TRACE',
        Level.debug   => 'DEBUG',
        Level.info    => 'INFO',
        Level.warning => 'WARN',
        Level.error   => 'ERROR',
        Level.fatal   => 'FATAL',
        _             => '???',
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(entry.level);
    final ts = entry.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.toPlainText()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log entry copied'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: level badge + timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(35),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _levelWord(entry.level),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: PresntTokens.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Message
            SelectableText(
              entry.message,
              style: TextStyle(
                fontSize: 13,
                color: entry.level == Level.error || entry.level == Level.fatal
                    ? color
                    : PresntTokens.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
