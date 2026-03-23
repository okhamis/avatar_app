import 'package:flutter/material.dart';
import '../../widgets/family_member_tile.dart';
import '../../models/family_member_model.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mockMember = FamilyMember(
      memberId: "m_1",
      accountId: "acc_1",
      name: "Jane Doe",
      relationship: "Spouse",
      accessTier: 2,
      addedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications),
            onPressed: () => context.goNamed(RouteNames.accessTiers),
          ),
          IconButton(
            icon: const Icon(Icons.health_and_safety),
            onPressed: () => context.goNamed(RouteNames.posthumousSettings),
          )
        ],
      ),
      body: ListView(
        children: [
          FamilyMemberTile(member: mockMember),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
