import 'package:flutter/material.dart';
import '../../../widgets/screens/goals/roadmap/follow_up_questions.dart';
import 'roadmap_lay_out_screen.dart';
import '../../../../utils/road_step_data.dart';

const List<RoadStepData> steps = [
  RoadStepData(
    title: "Meet Your Violin – Holding, Bowing & Posture",
    description: "Learn how to properly hold the violin and bow, and practice basic posture and hand positions. This week is all about comfort and familiarity. Spend time simply holding the instrument while watching videos or listening to gospel music to build a physical and emotional bond with it.",
  ),
  RoadStepData(
    title: "Open Strings, Clean Sound",
    description: "Practice long bows on open strings (G, D, A, E), focusing on smooth, even tone. Don't rush to use fingers yet. This is essential groundwork for beautiful sound later. Use a mirror or video to self-correct bow angle and arm movement.",
  ),
  RoadStepData(
    title: "Learn a Simple Hymn (By Ear or Sheet)",
    description: "Play \"Nearer My God to Thee\" on one or two strings using simple fingerings. Don't worry about perfection—feel the music. Play slowly and repeatedly. This is your first real connection to worship through the violin.",
  ),
  RoadStepData(
    title: "Left Hand Basics – Build Finger Dexterity",
    description: "Practice first-position finger placements (1st and 2nd finger) on D and A strings. Start simple scales (D major, G major). Focus on intonation (playing in tune) and ear training. Combine with open string bowing for a full-body experience.",
  ),
  RoadStepData(
    title: "Play a Full Short Piece (Intro + Chorus)",
    description: "Learn a short arrangement of \"Hallelujah\" (Leonard Cohen) or another simple gospel song. Use simplified fingering or tab-like notation if needed. It doesn't need to sound perfect—this is about expression. Record yourself and play for one person you trust.",
  ),
  RoadStepData(
    title: "Bowing Patterns + Gospel Groove",
    description: "Work on rhythm. Practice simple bowing patterns: slow/fast, staccato/legato. Start integrating fingered notes with rhythm. Try call-and-response exercises or mimic parts of gospel songs by ear. The goal is to move beyond \"note by note\" and into feeling.",
  ),
  RoadStepData(
    title: "Pick and Prepare a Song to Play for Church/Family",
    description: "Choose one meaningful song from your list or another one that's caught your heart. Begin polishing it. Focus on tone, timing, and expression. This is your offering. Play it daily with intention and love.",
  ),
  RoadStepData(
    title: "Play for Your Family or Record for Yourself",
    description: "Perform your chosen piece for someone—or record it. Reflect on how far you've come. This week is about courage, joy, and sharing. Whether at home or church, this is your moment of worship and testimony through music.",
  ),
];

const List<String> beforehands = [
  "Too much pressure on the bow causes scratchy, harsh sounds. Let it glide with gentle weight.",
  "Trying to play songs too early slows progress. Focus on technique first to unlock beauty later.",
  "Impatience with intonation is common—violin isn’t fretted like guitar. Your ears are your best tuner—give them time.",
  "Not celebrating small wins makes the journey feel longer. Even a clean open string or short hymn is a victory."
];

class RoadmapQuestionsScreen extends StatefulWidget {
  final List<String> questions;

  const RoadmapQuestionsScreen({
    super.key,
    required this.questions,
  });

  @override
  State<RoadmapQuestionsScreen> createState() => _RoadmapQuestionsScreenState();
}

class _RoadmapQuestionsScreenState extends State<RoadmapQuestionsScreen> {
  List<String> _answers = [];
  bool _showErrors = false;

  void _onAnswersChanged(List<String> answers) {
    setState(() {
      _answers = answers;
      // Optionally reset errors if all are answered
      if (_allAnswered) _showErrors = false;
    });
  }

  bool get _allAnswered =>
      _answers.length == widget.questions.length &&
      _answers.every((a) => a.trim().isNotEmpty);

  void _onSendPressed() {
    if (_allAnswered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoadmapLayOutScreen(steps: steps, beforehands: beforehands),
        ),
      );
    } else {
      setState(() {
        _showErrors = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FollowUpQuestions(
              questions: widget.questions,
              onAnswersComplete: _onAnswersChanged,
              showErrors: _showErrors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}