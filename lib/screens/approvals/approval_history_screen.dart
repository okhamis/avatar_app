import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class _HistoryItem {
  final String requester;
  final String credentialType;
  final String outcome; // approved | denied | expired
  final DateTime timestamp;

  const _HistoryItem({
    required this.requester,
    required this.credentialType,
    required this.outcome,
    required this.timestamp,
  });
}

class ApprovalHistoryScreen extends StatefulWidget {
  const ApprovalHistoryScreen({super.key});

  @override
  State<ApprovalHistoryScreen> createState() => _ApprovalHistoryScreenState();
}

class _ApprovalHistoryScreenState extends State<ApprovalHistoryScreen> {
  String _filter = 'All';

  final List<_HistoryItem> _history = [
    _HistoryItem(requester: 'Dr. Smith Clinic', credentialType: 'Insurance ID', outcome: 'approved', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    _HistoryItem(requester: 'Jane Doe', credentialType: 'Home Address', outcome: 'approved', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    _HistoryItem(requester: 'Unknown Caller', credentialType: 'SSN', outcome: 'denied', timestamp: DateTime.now().subtract(const Duration(days: 1))),
    _HistoryItem(requester: 'Bank Bot', credentialType: 'Account Number', outcome: 'expired', timestamp: DateTime.now().subtract(const Duration(days: 2))),
    _HistoryItem(requester: 'Delivery Service', credentialType: 'Home Address', outcome: 'approved', timestamp: DateTime.now().subtract(const Duration(days: 3))),
  ];

  List<_HistoryItem> get _filtered {
    if (_filter == 'All') return _history;
    return _history.where((h) => h.outcome == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Approval History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: ['All', 'Approved', 'Denied', 'Expired'].map((label) {
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
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No records.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        leading: _outcomeIcon(item.outcome),
                        title: Text(item.requester),
                        subtitle: Text('${item.credentialType} • ${_formatTime(item.timestamp)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _outcomeColor(item.outcome).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.outcome[0].toUpperCase() + item.outcome.substring(1),
                            style: TextStyle(
                              color: _outcomeColor(item.outcome),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _outcomeIcon(String outcome) {
    switch (outcome) {
      case 'approved':
        return const CircleAvatar(
          backgroundColor: AppColors.statusActive,
          radius: 18,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        );
      case 'denied':
        return const CircleAvatar(
          backgroundColor: AppColors.danger,
          radius: 18,
          child: Icon(Icons.close, color: Colors.white, size: 16),
        );
      default:
        return const CircleAvatar(
          backgroundColor: AppColors.statusSleeping,
          radius: 18,
          child: Icon(Icons.timer_off, color: Colors.white, size: 16),
        );
    }
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'approved': return AppColors.statusActive;
      case 'denied': return AppColors.danger;
      default: return AppColors.statusSleeping;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
