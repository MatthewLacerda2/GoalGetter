import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class TutorialScreen extends StatefulWidget {
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      pages: [
        PageViewModel(
          title: 'Welcome to Goal Getter',
          body: 'Track your goals and achieve your dreams with our intuitive app',
          image: Icon(
            Icons.flag,
            size: 80,
            color: Colors.white,
          ),
        ),
        PageViewModel(
          title: 'Set Your Goals',
          body: 'Create meaningful goals and break them down into manageable steps',
          image: Icon(
            Icons.flag,
            size: 80,
            color: Colors.white,
          ),
        ),
        PageViewModel(
          title: 'Track Progress',
          body: 'Monitor your daily progress and celebrate your achievements',
          image: Icon(
            Icons.trending_up,
            size: 80,
            color: Colors.white,
          ),
        ),
        PageViewModel(
          title: 'Stay Motivated',
          body: 'Get reminders and insights to keep you on track',
          image: Icon(
            Icons.lightbulb,
            size: 80,
            color: Colors.white,
          ),
        ),
      ],
      globalBackgroundColor: Colors.black87,
      skip: const Text('Skip', style: TextStyle(color: Colors.white)),
      next: const Text('Next', style: TextStyle(color: Colors.white)),
      done: const Text('Done', style: TextStyle(color: Colors.white)),
      onSkip: () => _navigateToHome(),
      onDone: () => _navigateToHome(),
      showSkipButton: true,
      showNextButton: true,
      showDoneButton: true,
      dotsDecorator: DotsDecorator(
        size: const Size(10, 10),
        color: Colors.white,
        activeSize: const Size(22, 10),
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