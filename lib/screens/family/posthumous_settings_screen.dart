import 'package:flutter/material.dart';

class PosthumousSettingsScreen extends StatelessWidget {
  const PosthumousSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Posthumous Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Enable Posthumous Mode"),
              subtitle: const Text("Requires Biometric to change"),
              value: true,
              onChanged: (val) {},
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text("Beneficiaries"),
              subtitle: Text("Jane Doe (Tier 1)"),
              trailing: Icon(Icons.edit),
            ),
            const TextField(
              decoration: InputDecoration(
                labelText: "Trusted Overseer ID",
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text("Blocked Actions"),
              subtitle: Text("Banking, Real Estate transfers"),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A1A),
              child: const Column(
                children: [
                  Icon(Icons.lock, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Digital Signature Valid", style: TextStyle(color: Colors.green)),
                  Text("Hash: 0x8A7B9...D92A", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text("Notice: Immutable after death.", style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
