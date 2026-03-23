import 'package:flutter/material.dart';
import '../models/session_model.dart';

class ConversationTile extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const ConversationTile({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.chat)),
      title: Text("With: ${session.targetContactName}"),
      subtitle: Text(session.isLive ? "Live now" : "Duration: 5m"),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        color: session.isLive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        child: Text(session.status),
      ),
      onTap: onTap,
    );
  }
}
