import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import '../../../widgets/screens/roadmap/roadmap_creation/goal_questions.dart';
import 'roadmap_lay_out_screen.dart';
import '../../../l10n/app_localizations.dart';

class RoadmapQuestionsScreen extends StatefulWidget {
  final List<String> questions;
  final String prompt;

  const RoadmapQuestionsScreen({
    super.key,
    required this.prompt,
    required this.questions,
  });

  @override
  State<RoadmapQuestionsScreen> createState() => _RoadmapQuestionsScreenState();
}

class _RoadmapQuestionsScreenState extends State<RoadmapQuestionsScreen> 
    with TickerProviderStateMixin {
  List<String> _answers = [];
  bool _showErrors = false;
  bool _isLoading = false;
  int _currentQuestionIndex = 0;
  
  // Animation controllers for sliding
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.questions.length, '');
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero, // End at center
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
    
    // Start with first question visible
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onAnswerSubmitted(String answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
      _showErrors = false;
    });

    // Move to next question or complete
    if (_currentQuestionIndex < widget.questions.length - 1) {
      _showNextQuestion();
    } else {
      // All questions answered, proceed to API call
      _onSendPressed();
    }
  }

  void _showNextQuestion() {
    // Slide current question out to the left
    _slideController.reverse().then((_) {
      setState(() {
        _currentQuestionIndex++;
      });
      // Slide new question in from the right
      _slideController.forward();
    });
  }

  bool get _allAnswered =>
      _answers.length == widget.questions.length &&
      _answers.every((a) => a.trim().isNotEmpty);

  Future<RoadmapCreationResponse?> _fetchRoadmapSteps(String prompt) async {
    List<FollowUpQuestionsAndAnswers> questionsAnswers = [];
    for (int i = 0; i < _answers.length; i++) {
      questionsAnswers.add(FollowUpQuestionsAndAnswers(
        question: widget.questions[i], 
        answer: _answers[i]
      ));
    }

    final roadmapApi = RoadmapApi(ApiClient(basePath: 'http://127.0.0.1:8000')); //TODO: read from env
    final request = RoadmapCreationRequest(
      prompt: prompt,
      questionsAnswers: questionsAnswers,
    );
    final response = await roadmapApi.createRoadmapApiV1RoadmapCreationPost(request);
    return response;
  }

  void _onSendPressed() async {
    if (_allAnswered) {
      setState(() {
        _isLoading = true;
      });
      try {
        final results = await _fetchRoadmapSteps(widget.prompt);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoadmapLayOutScreen(
              roadmapCreationResponse: results!,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.grey.shade200,
            content: Text(
              'Error: $e',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
        title: Text(AppLocalizations.of(context)!.questions),
        centerTitle: true,
        actions: [
          // Show progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GoalQuestions(
                  question: widget.questions[_currentQuestionIndex],
                  initialAnswer: _answers[_currentQuestionIndex].isNotEmpty 
                      ? _answers[_currentQuestionIndex] 
                      : null,
                  onAnswerSubmitted: _onAnswerSubmitted,
                  isActive: true,
                  showError: _showErrors,
                ),
              ),
            ),
          ),
          
          // Bottom navigation area - only next/complete button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey.shade300 : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentQuestionIndex < widget.questions.length - 1
                            ? AppLocalizations.of(context)!.next
                            : AppLocalizations.of(context)!.send,
                        style: const TextStyle(
                          fontSize: 18,
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