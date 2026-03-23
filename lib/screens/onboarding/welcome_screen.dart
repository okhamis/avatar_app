import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 80, color: Color(0xFF7F77DD)),
              const SizedBox(height: 24),
              const Text("Presnt", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Your AI Self. Always Available.", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Text("The first personal avatar that looks like you, sounds like you, and acts for you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.goNamed(RouteNames.createAccount),
                  child: const Text("Get Started"),
                ),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.home), // Skip to home for demo
                child: const Text("Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
