// Roadmap screen
import 'package:flutter/material.dart';
import '../widgets/infos_card.dart';

class LeaderBoardScreen extends StatelessWidget {
  const LeaderBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InfosCard(
          texts: [
            'Personal Records',
            'Awards',
            'Achievements',
            'My Division',
            'Overall Progress Towards the Goal',
          ],
        ),
      ),
    );
  }
}

