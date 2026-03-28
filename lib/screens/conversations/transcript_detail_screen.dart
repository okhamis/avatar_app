import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/session_model.dart';
import '../../core/providers/service_providers.dart';

class TranscriptDetailScreen extends ConsumerWidget {
  final String id;
  const TranscriptDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(authProvider)?.uid;
    if (accountId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transcript')),
        body: const Center(child: Text('Not signed in.')),
      );
    }

    final firebaseService = ref.read(firebaseServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transcript')),
      body: FutureBuilder<SessionModel?>(
        future: firebaseService.getSession(accountId, id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = snap.data;
          if (session == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Session: $id',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Session not found or transcript data is unavailable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              ),
            );
          }

          return _TranscriptBody(session: session);
        },
      ),
    );
  }
}

class _TranscriptBody extends StatelessWidget {
  final SessionModel session;
  const _TranscriptBody({required this.session});

  String _formatDuration(DateTime start, DateTime? end) {
    final duration = (end ?? DateTime.now()).difference(start);
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(session.targetContactName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: session.isLive
                            ? AppColors.statusActive.withValues(alpha: 0.12)
                            : AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(session.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: session.isLive ? AppColors.statusActive : AppColors.textSecondary,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Duration: ${_formatDuration(session.startTime, session.endTime)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (session.transcript.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No transcript entries recorded.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...session.transcript.map((entry) {
            final isAvatar = entry['isAvatar'] == true;
            final text = entry['text'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isAvatar
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    child: Icon(
                      isAvatar ? Icons.smart_toy : Icons.person,
                      size: 16,
                      color: isAvatar ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAvatar ? 'AI Proxy' : 'Participant',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvatar ? AppColors.primary : AppColors.textSecondary,
                            )),
                        const SizedBox(height: 4),
                        Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        if (session.actionsTaken.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Actions Taken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...session.actionsTaken.map((a) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: AppColors.statusActive, size: 20),
                title: Text(a, style: const TextStyle(fontSize: 13)),
              )),
        ],
      ],
    );
  }
}
