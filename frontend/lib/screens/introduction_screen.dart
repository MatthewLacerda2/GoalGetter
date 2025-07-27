import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';

class IntroductionScreenWidget extends StatelessWidget {
  const IntroductionScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Create your goal",
          body: "Write what you want to do and how much you'll dedicate to it weekly",
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
          title: "Create your Task",
          body: "Write down how you'll use your time for the day",
          image: const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.tasks,
                size: 90,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        PageViewModel(
          title: "Task to Goal",
          body: "You can mark a task as being part of achieving a goal",
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
          title: "Free tasks",
          body: "Not every task needs to achieve a big goal. Like doing the dishes",
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
          title: "Ready to achieve?",
          body: "Explore. Dream. Discover",
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
            builder: (BuildContext context) => const MyHomePage(title: 'Goal Getter'),
          ),
        );
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Text("Next"),
      done: const Text("Get Started"),
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