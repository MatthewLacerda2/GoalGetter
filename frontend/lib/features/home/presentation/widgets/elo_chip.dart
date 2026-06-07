import 'package:flutter/material.dart';

/// Compact elo (rating) pill for the top-left of the Home screen — the
/// counterpart to the streak chip on the top-right.
class EloChip extends StatelessWidget {
  final int elo;

  const EloChip({super.key, required this.elo});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: primary, size: 18),
          const SizedBox(width: 6.0),
          Text(
            '$elo',
            style: TextStyle(
              color: primary,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
