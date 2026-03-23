import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class VoiceRecordScreen extends StatelessWidget {
  const VoiceRecordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's capture your voice")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 3/6),
            const SizedBox(height: 32),
            const Text("Please read the following text aloud:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text(
              "\"I am setting up my Presnt avatar. This voice recording will be used to clone my vocal patterns, pitch, and tone so my avatar sounds exactly like me.\"",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE24B4A),
              child: IconButton(
                icon: const Icon(Icons.mic, size: 40, color: Colors.white),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {}, child: const Text("Play")),
                TextButton(onPressed: () {}, child: const Text("Re-record")),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.behavioralTraining),
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
