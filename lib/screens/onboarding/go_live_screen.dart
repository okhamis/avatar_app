import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class GoLiveScreen extends StatelessWidget {
  const GoLiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Color(0xFF5DCAA5)),
            const SizedBox(height: 32),
            const Text("You are live", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Your avatar is ready to represent you", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 32),
            const ListTile(
              leading: Icon(Icons.face, color: Color(0xFF7F77DD)),
              title: Text("Face Trained"),
            ),
            const ListTile(
              leading: Icon(Icons.mic, color: Color(0xFF7F77DD)),
              title: Text("Voice Cloned"),
            ),
            const ListTile(
              leading: Icon(Icons.psychology, color: Color(0xFF7F77DD)),
              title: Text("Personality Modeled"),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.home),
                child: const Text("Enter Presnt"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
