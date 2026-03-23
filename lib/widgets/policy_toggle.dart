import 'package:flutter/material.dart';

class PolicyToggle extends StatelessWidget {
  final String title;
  final int currentTier;
  final Function(int) onChanged;

  const PolicyToggle({super.key, required this.title, required this.currentTier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        DropdownButton<int>(
          value: currentTier,
          items: const [
            DropdownMenuItem(value: 1, child: Text("Tier 1: Auto")),
            DropdownMenuItem(value: 2, child: Text("Tier 2: Notify")),
            DropdownMenuItem(value: 3, child: Text("Tier 3: Wait")),
            DropdownMenuItem(value: 0, child: Text("Blocked")),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        )
      ],
    );
  }
}
