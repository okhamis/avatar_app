import 'package:flutter/material.dart';

class TranscriptDetailScreen extends StatelessWidget {
  final String id;
  const TranscriptDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transcript: $id")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Audit Trail", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Started: 10:00 AM\nEnded: 10:05 AM\nOutcome: Resolved", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text("Credentials Released", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const ListTile(
              leading: Icon(Icons.vpn_key),
              title: Text("Home Address"),
              subtitle: Text("Masked: 123 Main St, ***"),
            ),
            const SizedBox(height: 24),
            const Text("Transcript", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Mock Transcript
            ...List.generate(5, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(index % 2 == 0 ? "Avatar: Hello there." : "Contact: Hi, I need the address.", style: const TextStyle(fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }
}
