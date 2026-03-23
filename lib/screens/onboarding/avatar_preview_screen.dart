import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../widgets/avatar_display.dart';

class AvatarPreviewScreen extends StatelessWidget {
  const AvatarPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meet your avatar")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 5/6),
            const Spacer(),
            const AvatarDisplay(status: "active", fidelity: 0.95),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Text(
                "\"Hi, I am your Presnt avatar. I am ready to represent you.\"",
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text("Re-train model"),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.goLive),
                child: const Text("Approve and Go Live"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
