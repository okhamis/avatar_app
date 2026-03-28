import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  String _filter = 'All';

  List<SessionModel> _filtered(List<SessionModel> all) {
    switch (_filter) {
      case 'Active':
        return all.where((s) => s.isLive).toList();
      case 'Completed':
        return all.where((s) => !s.isLive).toList();
      default:
        return all;
    }
  }

  Color _tagColor(bool isLive) =>
      isLive ? AppColors.statusActive : AppColors.textSecondary;

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsListProvider);
    final items = _filtered(sessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Active', 'Completed'].map((label) {
                final active = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = label),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: active ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No conversations yet. Start a live session to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final session = items[i];
                final tag = session.isLive ? 'Active' : 'Completed';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: session.isLive
                        ? AppColors.statusActive.withValues(alpha: 0.2)
                        : AppColors.surface,
                    child: Text(
                      session.targetContactName.isNotEmpty ? session.targetContactName[0] : '?',
                      style: TextStyle(
                        color: session.isLive ? AppColors.statusActive : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(session.targetContactName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (session.isLive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.statusActive,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    _formatTime(session.startTime),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tagColor(session.isLive).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(color: _tagColor(session.isLive), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () {
                    if (session.isLive) {
                      context.pushNamed(RouteNames.liveConversation);
                    } else {
                      context.pushNamed(RouteNames.transcriptDetail, pathParameters: {'id': session.sessionId});
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.liveConversation),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.videocam),
        label: const Text('New Session'),
      ),
    );
  }
}
