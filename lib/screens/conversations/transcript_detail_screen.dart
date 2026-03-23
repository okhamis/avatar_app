import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class _TranscriptLine {
  final String speaker;
  final String text;
  final DateTime time;

  const _TranscriptLine({required this.speaker, required this.text, required this.time});
}

class TranscriptDetailScreen extends StatelessWidget {
  final String id;
  const TranscriptDetailScreen({super.key, required this.id});

  // Mock transcript lines — in production these come from Firestore
  List<_TranscriptLine> get _lines {
    final base = DateTime.now().subtract(const Duration(hours: 2));
    return [
      _TranscriptLine(speaker: 'Avatar', text: 'Hello, I am representing the user. How can I help you today?', time: base),
      _TranscriptLine(speaker: 'Contact', text: 'Hi, I need the home address for the delivery.', time: base.add(const Duration(seconds: 14))),
      _TranscriptLine(speaker: 'Avatar', text: 'I can help with that. Let me check if I have approval to share that information.', time: base.add(const Duration(seconds: 22))),
      _TranscriptLine(speaker: 'Avatar', text: 'The delivery address has been confirmed and forwarded securely.', time: base.add(const Duration(seconds: 65))),
      _TranscriptLine(speaker: 'Contact', text: 'Great, thank you!', time: base.add(const Duration(seconds: 72))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now().subtract(const Duration(hours: 2, minutes: 5));
    final end = start.add(const Duration(minutes: 4, seconds: 32));

    return Scaffold(
      appBar: AppBar(title: Text('Transcript')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audit trail
            _sectionHeader('Audit Trail'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _auditRow(Icons.play_arrow, 'Started', _formatTime(start)),
                  const Divider(height: 16),
                  _auditRow(Icons.stop, 'Ended', _formatTime(end)),
                  const Divider(height: 16),
                  _auditRow(Icons.check_circle, 'Outcome', 'Resolved'),
                  const Divider(height: 16),
                  _auditRow(Icons.timer, 'Duration', '4m 32s'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Credentials released
            _sectionHeader('Credentials Released'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.vpn_key, color: AppColors.primary),
                title: Text('Home Address'),
                subtitle: Text('Masked: 123 Main St, ***', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
                trailing: Icon(Icons.check_circle, color: AppColors.statusActive, size: 18),
              ),
            ),
            const SizedBox(height: 24),

            // Transcript
            _sectionHeader('Transcript'),
            ..._lines.map((line) {
              final isAvatar = line.speaker == 'Avatar';
              return Align(
                alignment: isAvatar ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: isAvatar ? AppColors.surface : AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.speaker,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvatar ? AppColors.secondary : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(line.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(line.time),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _auditRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
