import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class FollowUpQuestions extends StatefulWidget {
  final List<String> questions;
  final Function(List<String> answers)? onAnswersComplete;
  final bool showErrors; // NEW

  const FollowUpQuestions({
    super.key,
    required this.questions,
    this.onAnswersComplete,
    this.showErrors = false, // NEW
  });

  @override
  State<FollowUpQuestions> createState() => _FollowUpQuestionsState();
}

class _FollowUpQuestionsState extends State<FollowUpQuestions> 
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = [];
  final List<String> _answers = [];
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and answers for each question
    for (int i = 0; i < widget.questions.length; i++) {
      _controllers.add(TextEditingController());
      _answers.add('');
    }
    
    // Initialize animation controllers
    _animationControllers = List.generate(
      widget.questions.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)), // Staggered timing
        vsync: this,
      ),
    );
    
    // Initialize fade animations
    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Start animations with staggered delay
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    // Dispose animation controllers
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAnswerChanged(int index, String value) {
    setState(() {
      _answers[index] = value;
    });
    
    // Call callback if all questions are answered
    if (widget.onAnswersComplete != null && 
        _answers.every((answer) => answer.trim().isNotEmpty)) {
      widget.onAnswersComplete!(_answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final isEmpty = _answers[index].trim().isEmpty;
        return AnimatedBuilder(
          animation: _fadeAnimations[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _fadeAnimations[index].value)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text
                      Text(
                        widget.questions[index],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Answer input field
                      TextField(
                        controller: _controllers[index],
                        onChanged: (value) => _onAnswerChanged(index, value),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.yourAnswer,
                          border: UnderlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          // NEW: error styling
                          errorText: widget.showErrors && isEmpty ? AppLocalizations.of(context)!.pleaseAnswerThisQuestion : null,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: index < widget.questions.length - 1 
                            ? TextInputAction.next 
                            : TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}