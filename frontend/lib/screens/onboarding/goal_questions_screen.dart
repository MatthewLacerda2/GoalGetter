import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../widgets/screens/onboarding/goal_questions.dart';
import 'study_plan.dart';

class GoalQuestionsScreen extends StatefulWidget {
  final List<String> questions;
  final String prompt;

  const GoalQuestionsScreen({
    super.key,
    required this.prompt,
    required this.questions,
  });

  @override
  State<GoalQuestionsScreen> createState() => _GoalQuestionsScreenState();
}

class _GoalQuestionsScreenState extends State<GoalQuestionsScreen>
    with TickerProviderStateMixin {
  List<String> _answers = [];
  bool _showErrors = false;
  bool _isLoading = false;
  int _currentQuestionIndex = 0;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.questions.length, '');

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

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

    if (_currentQuestionIndex < widget.questions.length - 1) {
      _showNextQuestion();
    } else {
      _onSendPressed();
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

  bool get _allAnswered =>
      _answers.length == widget.questions.length &&
      _answers.every((a) => a.trim().isNotEmpty);

  void _onSendPressed() async {
    if (_allAnswered) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Get the Google token from AuthService
        final googleToken = _authService.getTempGoogleToken();
        if (googleToken == null) {
          throw Exception('No Google token available. Please sign in again.');
        }

        // Create API client and add the Google token as Authorization header
        final apiClient = ApiClient(basePath: AppConfig.baseUrl);
        apiClient.addDefaultHeader('Authorization', 'Bearer $googleToken');

        // Build request
        final api = OnboardingApi(apiClient);
        final qa = <GoalFollowUpQuestionAndAnswer>[];
        for (var i = 0; i < widget.questions.length; i++) {
          qa.add(
            GoalFollowUpQuestionAndAnswer(
              question: widget.questions[i],
              answer: _answers[i],
            ),
          );
        }
        final request = GoalStudyPlanRequest(
          prompt: widget.prompt,
          questionsAnswers: qa,
        );

        // Call API
        final plan = await api.generateStudyPlanApiV1OnboardingStudyPlanPost(
          request,
        );

        if (!mounted) return;
        if (plan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: empty study plan response',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        } else {
          // Navigate to Study Plan screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyPlanScreen(plan: plan),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'Error: $e';
        if (e.toString().contains('403')) {
          errorMessage =
              'Authentication failed (403). Please ensure you are signed in with Google. Error: $e';
        } else if (e.toString().contains('401')) {
          errorMessage =
              'Unauthorized (401). Your Google token may have expired. Please sign in again. Error: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            duration: const Duration(seconds: 5),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.questions),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentQuestionIndex < widget.questions.length - 1
                            ? AppLocalizations.of(context)!.next
                            : AppLocalizations.of(context)!.send,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
