import 'package:flutter/material.dart';
import '../models/session_model.dart';

class ConversationTile extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const ConversationTile({Key? key, required this.session, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.chat)),
      title: Text("With: ${session.targetContactName}"),
      subtitle: Text(session.isLive ? "Live now" : "Duration: 5m"),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        color: session.isLive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        child: Text(session.status),
      ),
      onTap: onTap,
    );
  }
}
