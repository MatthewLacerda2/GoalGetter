import 'package:flutter/cupertino.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
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
            AppLocalizations.of(context)!.trailwayToYourGoal,
            Icons.flag,
          ),
          _buildPageViewModel(
            AppLocalizations.of(context)!.objective,
            AppLocalizations.of(context)!.yourNextTarget,
            Icons.event_note,
          ),
          _buildPageViewModel(
            AppLocalizations.of(context)!.evaluation,
            AppLocalizations.of(context)!.evaluationDescription,
            CupertinoIcons.pencil_circle,
          ),
          _buildPageViewModel(
            AppLocalizations.of(context)!.tutor,
            AppLocalizations.of(context)!.tutorDescription,
            Icons.graphic_eq,
          ),
          _buildPageViewModel(
            AppLocalizations.of(context)!.awards,
            AppLocalizations.of(context)!.awardsDescription,
            Icons.emoji_events,
          ),
          _buildPageViewModel(
            AppLocalizations.of(context)!.goGetEmTiger,
            AppLocalizations.of(context)!.goGetEmTigerDescription,
            Icons.workspace_premium_outlined,
          ),
        ],
        globalBackgroundColor: Colors.black87,
        skip: Text(AppLocalizations.of(context)!.skip, style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
        next: Text(AppLocalizations.of(context)!.next, style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
        done: Text(AppLocalizations.of(context)!.done, style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
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