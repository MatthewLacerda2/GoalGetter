import 'package:flutter/material.dart';
import 'package:goal_getter/screens/task/calendar_screen.dart';

class TaskTabHeader extends StatelessWidget {
  final String goalTitle;
  final int streakCounter;
  final int xpLevel;

  final double buttonsHeight = 52;

  const TaskTabHeader({
    super.key,
    required this.goalTitle,
    required this.streakCounter,
    required this.xpLevel,
  });

  Widget _buildActionButton({
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    double? width,
  }) {
    return SizedBox(
      height: buttonsHeight,
      width: width,
      child: ElevatedButton(
        onPressed: onPressed ?? () {
          // Placeholder function
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(
            color: Colors.green,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.grey[100]!,
            icon: Icons.emoji_events,
            text: '$xpLevel',
            onPressed: () {
              // TODO: Implement xp functionality
            },
          ),
          const SizedBox(width: 12),
          Flexible(
            child: SizedBox(
              height: buttonsHeight,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement goal functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  goalTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.local_fire_department,
            text: '$streakCounter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(
                    streakCount: streakCounter,
                    sunday: false,
                    monday: true,
                    tuesday: true,
                    wednesday: true,
                    thursday: true,
                    friday: true,
                    saturday: false,
                    descriptionText: 'Yeah, keep the pressure on!!!',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}