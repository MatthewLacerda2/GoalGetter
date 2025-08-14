// calendar screen
import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  final int streakCount;
  final bool sunday;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final String descriptionText;

  const CalendarScreen({
    super.key,
    required this.streakCount,
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.descriptionText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 80,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'day streak!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: const [
                                Text('Su', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Mo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Tu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('We', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Th', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Fr', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Sa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildProgressIndicator(sunday),
                                _buildProgressIndicator(monday),
                                _buildProgressIndicator(tuesday),
                                _buildProgressIndicator(wednesday),
                                _buildProgressIndicator(thursday),
                                _buildProgressIndicator(friday),
                                _buildProgressIndicator(saturday),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.grey, thickness: 1),
                            const SizedBox(height: 20),
                            Text(
                              descriptionText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? Colors.green : Colors.red,
      ),
      child: Icon(
        isCompleted ? Icons.check : Icons.close,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}