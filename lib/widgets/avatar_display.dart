import 'package:flutter/material.dart';

class AvatarDisplay extends StatelessWidget {
  final String status; // active, sleeping, busy
  final double fidelity;

  const AvatarDisplay({Key? key, required this.status, required this.fidelity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      switch (status) {
        case 'active': return const Color(0xFF5DCAA5);
        case 'busy': return const Color(0xFFEF9F27);
        default: return const Color(0xFF888780);
      }
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        shape: BoxShape.circle,
        border: Border.all(color: getStatusColor(), width: 4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.person, size: 100, color: Color(0xFF888780)),
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Fidelity ${((fidelity) * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          )
        ],
      ),
    );
  }
}
