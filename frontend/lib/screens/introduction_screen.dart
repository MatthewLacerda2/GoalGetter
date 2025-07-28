import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';

class IntroductionScreenWidget extends StatelessWidget {
  const IntroductionScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: AppLocalizations.of(context)!.createYourGoal,
          body: AppLocalizations.of(context)!.writeWhatYouWantToDoAndHowMuchYouWillDedicateToItWeekly,
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.bullseye,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        PageViewModel(
          title: AppLocalizations.of(context)!.createYourTask,
          body: AppLocalizations.of(context)!.writeDownHowYouWillUseYourTimeForTheDay,
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.listCheck,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        PageViewModel(
          title: AppLocalizations.of(context)!.taskToGoal,
          body: AppLocalizations.of(context)!.youCanMarkATaskAsBeingPartOfAchievingAGoal,
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.link,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        PageViewModel(
          title: AppLocalizations.of(context)!.freeTasks,
          body: AppLocalizations.of(context)!.notEveryTaskNeedsToAchieveABigGoalLikeDoingTheDishes,
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.utensils,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        PageViewModel(
          title: AppLocalizations.of(context)!.readyToAchieve,
          body: AppLocalizations.of(context)!.exploreDreamDiscover,
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.rocket,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
      ],
      onDone: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MyHomePage(title: 'Goal Getter', onLanguageChanged: (String language) {}),
          ),
        );
      },
      showSkipButton: true,
      skip: Text(AppLocalizations.of(context)!.skip),
      next: Text(AppLocalizations.of(context)!.next),
      done: Text(AppLocalizations.of(context)!.getStarted),
      dotsDecorator: DotsDecorator(
        activeColor: Theme.of(context).primaryColor,
        size: const Size(10.0, 10.0),
        color: Colors.grey,
        activeSize: const Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      globalBackgroundColor: Colors.white,
    );
  }
}