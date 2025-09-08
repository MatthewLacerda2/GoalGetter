import 'package:flutter/material.dart';
import '../../models/fake_evaluation_questions.dart';
import '../../l10n/app_localizations.dart';
import 'finish_evaluation_screen.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> 
    with TickerProviderStateMixin {
  List<String> _answers = [];
  bool _showErrors = false;
  int _currentQuestionIndex = 0;
  bool _showEvaluation = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(fakeEvaluationAnswers.length, '');
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

  void _onAnswerSubmitted(String answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
      _showErrors = false;
      _showEvaluation = true;
    });
  }

  void _onNextPressed() {
    if (_currentQuestionIndex < fakeEvaluationAnswers.length - 1) {
      _showNextQuestion();
    } else {
      _onFinishPressed();
    }
  }

  void _showNextQuestion() {
    _slideController.reverse().then((_) {
      setState(() {
        _currentQuestionIndex++;
        _showEvaluation = false;
      });
      _slideController.forward();
    });
  }

  void _onFinishPressed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FinishEvaluationScreen(),
      ),
    );
  }

  bool get _currentAnswerSubmitted => _answers[_currentQuestionIndex].trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final currentQuestion = fakeEvaluationAnswers[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 43, 43),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.evaluation),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${fakeEvaluationAnswers.length}',
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
                child: _EvaluationQuestion(
                  question: currentQuestion.question,
                  studentAnswer: _answers[_currentQuestionIndex],
                  llmEvaluation: currentQuestion.llmEvaluation,
                  isCorrect: currentQuestion.isCorrect,
                  showEvaluation: _showEvaluation,
                  onAnswerSubmitted: _onAnswerSubmitted,
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
                onPressed: _currentAnswerSubmitted ? _onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentAnswerSubmitted
                      ? (fakeEvaluationAnswers[_currentQuestionIndex].isCorrect 
                          ? Colors.green 
                          : Colors.red)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < fakeEvaluationAnswers.length - 1
                      ? AppLocalizations.of(context)!.next
                      : AppLocalizations.of(context)!.done,
                  style: const TextStyle(
                    fontSize: 20,
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

class _EvaluationQuestion extends StatefulWidget {
  final String question;
  final String studentAnswer;
  final String llmEvaluation;
  final bool isCorrect;
  final bool showEvaluation;
  final Function(String answer) onAnswerSubmitted;
  final bool showError;

  const _EvaluationQuestion({
    required this.question,
    required this.studentAnswer,
    required this.llmEvaluation,
    required this.isCorrect,
    required this.showEvaluation,
    required this.onAnswerSubmitted,
    this.showError = false,
  });

  @override
  State<_EvaluationQuestion> createState() => _EvaluationQuestionState();
}

class _EvaluationQuestionState extends State<_EvaluationQuestion> {
  late TextEditingController _textController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    if (widget.studentAnswer.isNotEmpty) {
      _textController.text = widget.studentAnswer;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    widget.onAnswerSubmitted(trimmedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 43, 43, 43),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              widget.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Answer input field
            TextField(
              controller: _textController,
              enabled: !widget.showEvaluation,
              onSubmitted: widget.showEvaluation ? null : _handleSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.yourAnswer,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: !widget.showEvaluation 
                    ? Colors.grey[800]
                    : Colors.grey[700],
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                errorText: (widget.showError || _hasError) && _textController.text.trim().isEmpty
                    ? AppLocalizations.of(context)!.pleaseAnswerThisQuestion
                    : null,
                suffixIcon: !widget.showEvaluation
                    ? IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _handleSubmitted(_textController.text),
                        tooltip: 'Submit',
                      )
                    : null,
              ),
              minLines: 5,              textInputAction: TextInputAction.send,
              maxLines: 10,
              onChanged: (value) {
                if (_hasError && value.trim().isNotEmpty) {
                  setState(() {
                    _hasError = false;
                  });
                }
              },
            ),
            
            // Show evaluation if answer has been submitted
            if (widget.showEvaluation) ...[
              const SizedBox(height: 16),
              
              // LLM evaluation display
              Text(
                widget.llmEvaluation,
                style: TextStyle(
                  fontSize: 20,
                  color: widget.isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}