import 'package:flutter/material.dart';
import '../widgets/info_card.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Card Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InfoCard(
              title: 'First Card',
              description: 'This is the first info card for testing purposes.',
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Second Card',
              description: 'This is the second info card with different content.',
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Third Card',
              description: 'The third card shows how the widget looks with longer descriptions.',
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Fourth Card',
              description: 'Another test card to verify the styling and layout.',
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Fifth Card',
              description: 'The final test card to complete the set of 5 info cards.',
            ),
          ],
        ),
      ),
    );
  }
}