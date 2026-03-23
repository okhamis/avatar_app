import 'package:flutter/material.dart';

class LiveConversationScreen extends StatelessWidget {
  const LiveConversationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Session"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("04:32", style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            color: Colors.black,
            child: const Center(child: Text("Avatar Video Feed Area (Placeholder)")),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                final isAvatar = index % 2 == 0;
                return Align(
                  alignment: isAvatar ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvatar ? const Color(0xFF7F77DD).withOpacity(0.2) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(isAvatar ? "Avatar response $index" : "Contact message $index"),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
                    child: const Text("End Session"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Take Over"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
