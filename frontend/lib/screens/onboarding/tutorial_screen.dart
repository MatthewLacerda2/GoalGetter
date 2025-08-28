import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class TutorialScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;
  
  const TutorialScreen({super.key, this.onLanguageChanged});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  PageViewModel _buildPageViewModel(String title, String body, IconData icon) {
    return PageViewModel(
      titleWidget: Text(title, style: TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold)),
      bodyWidget: Text(body, style: TextStyle(color: Colors.white, fontSize: 18)),
      image: Icon(icon, size: 104, color: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      pages: [
        _buildPageViewModel(    
          'Welcome to Goal Getter',
          'A curated trailway to your goal',
          Icons.flag,
        ),
        _buildPageViewModel(
          'Objective',
          'Your current objective towards your goal. We got your next assignment, tips and exercises',
          Icons.event_note,
        ),
        _buildPageViewModel(
          'Tutor Test',
          'The Objective Screen got a test where you chat with a Tutor. He will evaluate your progress and pass you to the next objectives',
          Icons.graphic_eq,
        ),
        _buildPageViewModel(
          'Tutor',
          'We got someone to keep an eye on you. He will remember your chat, get to know you, you can ask questions and get advice',
          Icons.workspace_premium_outlined,
        ),
        _buildPageViewModel(
          'Achievements', 'Your milestones and progress listed. Make it your gallery!', Icons.emoji_events_outlined,
        ),
        _buildPageViewModel(
          'Go get \'em, tiger!',
          'Explore. Dream. Discover.',
          Icons.workspace_premium_outlined,
        ),
      ],
      globalBackgroundColor: Colors.black87,
      skip: const Text('Skip', style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
      next: const Text('Next', style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
      done: const Text('Done', style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
      onSkip: () => _navigateToHome(),
      onDone: () => _navigateToHome(),
      showSkipButton: true,
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8),
        color: Colors.orange,
        activeSize: const Size(14, 14),
        activeColor: Colors.orange,
      ),
    );
  }

  void _navigateToHome() {
    final newRoute = MaterialPageRoute(
      builder: (context) => MyHomePage(
        title: 'Goal Getter',
        onLanguageChanged: (language) {},
        selectedIndex: 0,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(newRoute, (route) => false);
  }
}