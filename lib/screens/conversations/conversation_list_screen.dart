import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(label: Text("All"), onSelected: null),
                SizedBox(width: 8),
                FilterChip(label: Text("Active"), onSelected: null),
                SizedBox(width: 8),
                FilterChip(label: Text("Completed"), onSelected: null),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final isLive = index == 0;
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text("Contact $index"),
            subtitle: Text(isLive ? "Live now" : "1 hour ago • Duration 4m"),
            trailing: Chip(
              label: Text(isLive ? "Active" : "Resolved"),
              backgroundColor: isLive ? const Color(0xFF5DCAA5).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            ),
            onTap: () {
              if (isLive) {
                context.goNamed(RouteNames.liveConversation);
              } else {
                context.goNamed(RouteNames.transcriptDetail, pathParameters: {'id': 'session_$index'});
              }
            },
          );
        },
      ),
    );
  }
}
