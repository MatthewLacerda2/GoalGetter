import 'package:flutter/cupertino.dart';
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
      bodyWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          body, 
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      image: Icon(icon, size: 104, color: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IntroductionScreen(
        key: _introKey,
        pages: [
          _buildPageViewModel(    
            'Goal Getter!',
            'A trailway to your goal',
            Icons.flag,
          ),
          _buildPageViewModel(
            'Objective',
            'Your next target. Take the materials and exercises we got for you',
            Icons.event_note,
          ),
          _buildPageViewModel(
            'Evaluation',
            'You can check your progress and get your next objective when you\'re ready',
            CupertinoIcons.pencil_circle,
          ),
          _buildPageViewModel(
            'Tutor',
            'We got someone to give you advice, answer questions and guide you through',
            Icons.graphic_eq,
          ),
          _buildPageViewModel(
            'Awards', 'Your milestones and progress listed! Make it your gallery!', Icons.emoji_events,
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