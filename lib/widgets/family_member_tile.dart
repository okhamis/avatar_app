import 'package:flutter/material.dart';
import '../models/family_member_model.dart';

class FamilyMemberTile extends StatelessWidget {
  final FamilyMember member;

  const FamilyMemberTile({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(member.name[0])),
      title: Text(member.name),
      subtitle: Text("Relationship: ${member.relationship} \nTier: ${member.accessTier}"),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {},
      ),
    );
  }
}
