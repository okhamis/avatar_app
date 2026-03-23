import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../widgets/avatar_display.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presnt"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const AvatarDisplay(status: "active", fidelity: 0.95),
            const SizedBox(height: 16),
            const Text("Your Personal AI Avatar", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("Active Sessions", "0"),
                _buildStatColumn("Pending Approvals", "2"),
                _buildStatColumn("Tasks Completed", "14"),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                title: const Text("Last Action"),
                subtitle: const Text("Scheduled dentist appointment for next Tuesday"),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF5DCAA5)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pushNamed(RouteNames.liveConversation),
                icon: const Icon(Icons.chat),
                label: const Text("Start Conversation"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
