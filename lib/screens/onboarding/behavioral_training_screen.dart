import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class BehavioralTrainingScreen extends StatelessWidget {
  const BehavioralTrainingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final questions = [
      "How would you describe your communication style?",
      "What are your core values?",
      "How do you typically respond when someone asks for a favor?"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Behavioral Training")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 4/6),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(questions[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const TextField(
                          maxLines: 3,
                          decoration: InputDecoration(hintText: "Type your answer..."),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.avatarPreview),
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
