import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class Leaderboarder extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final int startingPosition;
  final String username;

  const Leaderboarder({
    super.key,
    required this.people,
    required this.startingPosition,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < people.length; i++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: people[i]['name'] == username 
                    ? const Color.fromARGB(255, 80, 80, 80)
                    : const Color.fromARGB(255, 53, 53, 53),
                borderRadius: i == 0 
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      )
                    : i == people.length - 1
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          )
                        : null,
              ),
              child: Row(
                children: [
                  // Position
                  Text(
                    '${startingPosition + i}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name
                  Expanded(
                    child: Text(
                      people[i]['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // XP Amount
                  Text(
                    '${people[i]['xpAmount']} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Divider between people (except after the last one)
            if (i < people.length - 1)
              Container(
                height: 1,
                color: Colors.grey,
              ),
          ],
        ],
      ),
    );
  }
}