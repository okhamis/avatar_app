import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../widgets/family_member_tile.dart';
import '../../models/family_member_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    var selectedTier = 2;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: PresntTokens.surfaceContainerHigh,
          title: Text('Add Family Member', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.manrope(),
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relCtrl,
                style: GoogleFonts.manrope(),
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedTier,
                dropdownColor: PresntTokens.surfaceContainer,
                decoration: const InputDecoration(labelText: 'Access Tier'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Tier 1 — Autonomous')),
                  DropdownMenuItem(value: 2, child: Text('Tier 2 — Notify')),
                  DropdownMenuItem(value: 3, child: Text('Tier 3 — Approval')),
                  DropdownMenuItem(value: 0, child: Text('Blocked')),
                ],
                onChanged: (v) => setDialogState(() => selectedTier = v ?? 2),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final accountId = ref.read(authProvider)?.uid;
                if (accountId == null) return;
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(familyMembersProvider.notifier).addMember(FamilyMember(
                        memberId: 'm_${DateTime.now().millisecondsSinceEpoch}',
                        accountId: accountId,
                        name: nameCtrl.text.trim(),
                        relationship: relCtrl.text.trim().isEmpty ? 'Family' : relCtrl.text.trim(),
                        accessTier: selectedTier,
                        addedAt: DateTime.now(),
                      ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountId = ref.watch(authProvider)?.uid;
    final members = ref
        .watch(familyMembersProvider)
        .where((member) => accountId != null && member.accountId == accountId)
        .toList();

    return Scaffold(
      backgroundColor: PresntTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 16),
                  decoration: BoxDecoration(
                    color: PresntTokens.surface.withValues(alpha: 0.55),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: PresntTokens.surfaceContainerHigh,
                        child: const Icon(Icons.groups_2_rounded, color: PresntTokens.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Digital Concierge',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: PresntTokens.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded, color: Colors.white70),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.fingerprint_rounded, color: PresntTokens.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'SECURITY & GOVERNANCE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: PresntTokens.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Family Circle',
                  style: GoogleFonts.manrope(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Manage your digital ecosystem's access levels. Control how your AI Concierge interacts with family members.",
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    height: 1.5,
                    color: PresntTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _tierBento(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Members',
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} members currently have verified access.',
                          style: GoogleFonts.manrope(fontSize: 13, color: PresntTokens.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No family members yet.',
                        style: GoogleFonts.manrope(color: PresntTokens.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...members.map((m) => FamilyMemberTile(member: m)),
                const SizedBox(height: 24),
                _securityPanel(),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        backgroundColor: PresntTokens.ctaPurple,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add Family Member', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _tierBento() {
    Widget card({required IconData icon, required Color ic, required String title, required String body, String? tag}) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: PresntTokens.surfaceContainer.withValues(alpha: 0.65),
          border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: ic.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: ic),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              body,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.45,
                color: PresntTokens.onSurfaceVariant,
              ),
            ),
            if (tag != null) ...[
              const SizedBox(height: 14),
              Text(
                tag.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: PresntTokens.secondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: card(
                  icon: Icons.bolt_rounded,
                  ic: PresntTokens.secondary,
                  title: 'Tier 1: Autonomous',
                  body: 'Full clearance. Concierge executes requests immediately without external confirmation.',
                  tag: 'Active policy',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: card(
                  icon: Icons.notifications_active_rounded,
                  ic: PresntTokens.primary,
                  title: 'Tier 2: Notify',
                  body: 'Concierge executes and sends a summary log to your primary device.',
                  tag: 'Default setting',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: card(
                  icon: Icons.lock_clock_rounded,
                  ic: PresntTokens.tertiary,
                  title: 'Tier 3: Approval',
                  body: 'Execution is paused until you verify.',
                  tag: 'High security',
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            card(
              icon: Icons.bolt_rounded,
              ic: PresntTokens.secondary,
              title: 'Tier 1: Autonomous',
              body: 'Full clearance. Concierge executes immediately.',
              tag: 'Active policy',
            ),
            const SizedBox(height: 14),
            card(
              icon: Icons.notifications_active_rounded,
              ic: PresntTokens.primary,
              title: 'Tier 2: Notify',
              body: 'Executes and notifies you.',
              tag: 'Default',
            ),
            const SizedBox(height: 14),
            card(
              icon: Icons.lock_clock_rounded,
              ic: PresntTokens.tertiary,
              title: 'Tier 3: Approval',
              body: 'Waits for your approval.',
              tag: 'High security',
            ),
          ],
        );
      },
    );
  }

  Widget _securityPanel() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: PresntTokens.surfaceContainer.withValues(alpha: 0.65),
        border: Border.all(color: PresntTokens.outlineVariant.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity Verification Pulse',
                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Concierge is monitoring linked profiles. Review security logs anytime.',
                  style: GoogleFonts.manrope(fontSize: 13, height: 1.45, color: PresntTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.goNamed(RouteNames.accessTiers),
                      child: const Text('Access tiers'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.goNamed(RouteNames.posthumousSettings),
                      child: const Text('Posthumous'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PresntTokens.secondary.withValues(alpha: 0.35), width: 2, style: BorderStyle.solid),
            ),
            child: const Icon(Icons.verified_user_rounded, size: 40, color: PresntTokens.secondary),
          ),
        ],
      ),
    );
  }
}
