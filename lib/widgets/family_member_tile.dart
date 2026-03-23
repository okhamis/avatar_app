import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/family_member_model.dart';
import '../theme/presnt_tokens.dart';

class FamilyMemberTile extends StatelessWidget {
  final FamilyMember member;

  const FamilyMemberTile({super.key, required this.member});

  String _tierLabel() {
    switch (member.accessTier) {
      case 1:
        return 'Tier 1: Autonomous';
      case 2:
        return 'Tier 2: Notify';
      case 3:
        return 'Tier 3: Approval';
      case 0:
        return 'Blocked';
      default:
        return 'Tier ${member.accessTier}';
    }
  }

  Color _tierColor() {
    switch (member.accessTier) {
      case 1:
        return PresntTokens.secondary;
      case 2:
        return PresntTokens.primary;
      case 3:
        return PresntTokens.tertiary;
      default:
        return PresntTokens.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _tierColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: PresntTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: PresntTokens.surfaceContainerHighest,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: PresntTokens.primary),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.relationship.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: PresntTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ACCESS TIER',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: PresntTokens.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tc.withValues(alpha: 0.28)),
                      ),
                      child: Text(
                        _tierLabel(),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tc,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert_rounded, color: PresntTokens.outlineVariant.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
