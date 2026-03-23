import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LinearProgressIndicator(value: 1/6),
            const SizedBox(height: 32),
            const TextField(decoration: InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: "Password"), obscureText: true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.faceUpload),
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
