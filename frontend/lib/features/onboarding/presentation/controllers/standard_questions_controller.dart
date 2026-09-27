import 'dart:async';

import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/question_timer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'standard_questions_controller.g.dart';

/// The standard questions of one new goal: which is on screen, what he
/// answered, and whether he is done with them.
final class StandardQuestionsState {
  const StandardQuestionsState({
    required this.index,
    required this.answers,
    required this.done,
  });

  /// The question on screen.
  final int index;

  /// What he answered so far, in the order he answered.
  final List<StandardAnswer> answers;

  /// He answered the last one or skipped the rest: his lesson is next.
  final bool done;

  /// The option he picked for [questionKey], or null.
  String? selected(String questionKey) {
    for (final answer in answers) {
      if (answer.questionKey == questionKey) return answer.optionKey;
    }
    return null;
  }
}

/// The last step of goal creation (#132): [questions] of goal [goalId],
/// answered while its first lesson generates.
///
/// [questions] are the ones the screen can draw — it leaves out a key this
/// build has no sentence for — so every index here is one on screen.
///
/// **Nothing here blocks.** The answers are sent without waiting and a failure
/// is swallowed on purpose: they are worth having and worth nothing at all
/// compared with the lesson he is on his way to, and there is no screen on
/// which to show him an error about a question he has finished with.
@riverpod
class StandardQuestionsController extends _$StandardQuestionsController {
  late QuestionTimer _timer;

  @override
  StandardQuestionsState build(
    String goalId,
    List<StandardQuestion> questions,
  ) {
    _timer = QuestionTimer(questions.length);
    if (questions.isNotEmpty) _timer.show(0);
    return const StandardQuestionsState(index: 0, answers: [], done: false);
  }

  /// [optionKey] answers the question on screen, and its clock stops. False
  /// once he is done.
  bool pick(String optionKey) {
    if (state.done) return false;
    _timer.stop();
    final answer = StandardAnswer(
      questionKey: questions[state.index].key,
      optionKey: optionKey,
      totalSeconds: _timer.secondsOn(state.index),
    );
    state = StandardQuestionsState(
      index: state.index,
      answers: [...state.answers, answer],
      done: false,
    );
    return true;
  }

  /// The next question takes the screen, or, after the last, he is done.
  void advance() {
    if (state.done) return;
    if (state.index >= questions.length - 1) return finish();
    final index = state.index + 1;
    state = StandardQuestionsState(
      index: index,
      answers: state.answers,
      done: false,
    );
    _timer.show(index);
  }

  /// Sends what he answered, without waiting, and marks him done.
  void finish() {
    if (state.done) return;
    final answers = state.answers;
    if (answers.isNotEmpty) {
      unawaited(
        ref
            .read(onboardingApiProvider)
            .sendStandardAnswers(goalId, List.of(answers))
            .catchError((_) {}),
      );
    }
    state = StandardQuestionsState(
      index: state.index,
      answers: answers,
      done: true,
    );
  }
}
