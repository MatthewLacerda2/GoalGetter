import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../app/app.dart';
class TutorialScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  TutorialScreen({super.key, this.onLanguageChanged});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  PageViewModel _buildPageViewModel(String title, String body, IconData icon) {
    return PageViewModel(
      useScrollView: true,
      titleWidget: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 28,
            ),
      ),
      bodyWidget: Container(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
      image: Icon(
        icon,
        size: 104,
        color: Theme.of(context).colorScheme.secondary,
      ),
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
        globalBackgroundColor: Theme.of(context).colorScheme.surface,
        skip: Text(
          AppLocalizations.of(context)!.skip,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        next: Text(
          AppLocalizations.of(context)!.next,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        done: Text(
          AppLocalizations.of(context)!.done,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        onSkip: () => _navigateToHome(),
        onDone: () => _navigateToHome(),
        showSkipButton: true,
        dotsDecorator: DotsDecorator(
          size: Size(8, 8),
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          activeSize: Size(14, 14),
          activeColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
      arguments: HomeRouteArgs(selectedIndex: 0),
    );
  }
}
