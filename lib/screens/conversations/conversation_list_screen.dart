import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';

class _ConvItem {
  final String id;
  final String contact;
  final String subtitle;
  final String tag;
  final bool isLive;

  const _ConvItem({
    required this.id,
    required this.contact,
    required this.subtitle,
    required this.tag,
    required this.isLive,
  });
}

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  String _filter = 'All';

  final List<_ConvItem> _all = const [];

  List<_ConvItem> get _filtered {
    switch (_filter) {
      case 'Active': return _all.where((c) => c.isLive).toList();
      case 'Completed': return _all.where((c) => !c.isLive).toList();
      default: return _all;
    }
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Active': return AppColors.statusActive;
      case 'Pending Approval': return AppColors.statusBusy;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

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
                  'No conversations yet. Start a live session to create one, or connect a session store to list past calls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: item.isLive
                        ? AppColors.statusActive.withValues(alpha: 0.2)
                        : AppColors.surface,
                    child: Text(
                      item.contact[0],
                      style: TextStyle(
                        color: item.isLive ? AppColors.statusActive : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(item.contact, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.isLive) ...[
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
                    item.subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tagColor(item.tag).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.tag,
                      style: TextStyle(color: _tagColor(item.tag), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () {
                    if (item.isLive) {
                      context.pushNamed(RouteNames.liveConversation);
                    } else {
                      context.pushNamed(RouteNames.transcriptDetail, pathParameters: {'id': item.id});
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
