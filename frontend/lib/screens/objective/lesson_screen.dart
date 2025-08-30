import 'package:flutter/material.dart';
import '../../models/question_data.dart';
import '../../widgets/screens/objective/lesson/lesson_question.dart';
import '../intermediate/finish_lesson_screen.dart';
//TODO: put the header with information notes
class LessonScreen extends StatefulWidget {
  final List<QuestionData> questions;
  final String title;

  const LessonScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> 
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 425),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onQuestionAnswered() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      _showNextQuestion();
    } else {
      _onAllQuestionsCompleted();
    }
  }

  void _showNextQuestion() {
    _slideController.reverse().then((_) {
      setState(() {
        _currentQuestionIndex++;
      });
      _slideController.forward();
    });
  }

  void _onAllQuestionsCompleted() {
    //TODO: put screen sayin' we'll repeat the wrong answered questions. put it only once, and nonce if we got 'em all right
    //then put the info screen saying we won
    //Obviously, we're missing storage and api usage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => FinishLessonScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false, // Add this line
        title: Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        //TODO: put a bar that shows how many you got right on the first try
      ),
      body: Container(
        color: const Color.fromARGB(255, 43, 43, 43),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: LessonQuestion(
                      key: ValueKey(_currentQuestionIndex),
                      questionData: widget.questions[_currentQuestionIndex],
                      onQuestionAnswered: _onQuestionAnswered,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}