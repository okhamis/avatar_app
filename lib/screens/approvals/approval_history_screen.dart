import 'package:flutter/material.dart';

class ApprovalHistoryScreen extends StatelessWidget {
  const ApprovalHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          final approved = index % 2 == 0;
          return ListTile(
            leading: Icon(approved ? Icons.check_circle : Icons.cancel, color: approved ? const Color(0xFF5DCAA5) : const Color(0xFFE24B4A)),
            title: Text("Request $index"),
            subtitle: const Text("Yesterday"),
          );
        },
      ),
    );
  }
}
