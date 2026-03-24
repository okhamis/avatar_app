import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Placeholder until transcripts are loaded from Firestore or your session API.
class TranscriptDetailScreen extends StatelessWidget {
  final String id;
  const TranscriptDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transcript')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Session: $id',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Transcript content is not stored in the app yet. Wire this screen to your session or Firestore collection when ready.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
