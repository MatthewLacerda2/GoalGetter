import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/features/lessons/domain/lesson_question_data.dart';
import 'package:goal_getter/core/services/api_client_provider.dart';

class LessonQuestionState {
  final MultipleChoiceQuestionResponse apiQuestion;
  final LessonQuestionStatus status;
  final DateTime? startTime;
  final int? studentAnswerIndex;
  final int? secondsSpent;

  LessonQuestionState({
    required this.apiQuestion,
    this.status = LessonQuestionStatus.notAnswered,
    this.startTime,
    this.studentAnswerIndex,
    this.secondsSpent,
  });

  LessonQuestionState copyWith({
    LessonQuestionStatus? status,
    DateTime? startTime,
    int? studentAnswerIndex,
    int? secondsSpent,
  }) {
    return LessonQuestionState(
      apiQuestion: this.apiQuestion,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      studentAnswerIndex: studentAnswerIndex ?? this.studentAnswerIndex,
      secondsSpent: secondsSpent ?? this.secondsSpent,
    );
  }
}

class LessonState {
  final List<LessonQuestionState> questions;
  final int currentQuestionIndex;
  final int? selectedChoiceIndex;
  final bool isAnswerRevealed;
  final bool isReviewMode;
  final bool isLoading;
  final String? errorMessage;
  final Duration totalTimeSpent;
  final MultipleChoiceActivityEvaluationResponse? evaluationResponse;
  final bool isCompleted;

  LessonState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedChoiceIndex,
    this.isAnswerRevealed = false,
    this.isReviewMode = false,
    this.isLoading = true,
    this.errorMessage,
    this.totalTimeSpent = Duration.zero,
    this.evaluationResponse,
    this.isCompleted = false,
  });

  LessonState copyWith({
    List<LessonQuestionState>? questions,
    int? currentQuestionIndex,
    int? selectedChoiceIndex,
    bool? isAnswerRevealed,
    bool? isReviewMode,
    bool? isLoading,
    String? errorMessage,
    Duration? totalTimeSpent,
    MultipleChoiceActivityEvaluationResponse? evaluationResponse,
    bool? isCompleted,
  }) {
    return LessonState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedChoiceIndex: selectedChoiceIndex,
      isAnswerRevealed: isAnswerRevealed ?? this.isAnswerRevealed,
      isReviewMode: isReviewMode ?? this.isReviewMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      evaluationResponse: evaluationResponse ?? this.evaluationResponse,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class LessonNotifier extends StateNotifier<LessonState> {
  LessonNotifier(this._ref) : super(LessonState());

  final Ref _ref;
  Timer? _timer;
  late DateTime _startTime;
  bool _hasSubmittedAnswers = false;

  void init(List<LessonQuestionData>? legacyQuestions) {
    _startTime = DateTime.now();
    _startTimer();

    if (legacyQuestions != null && legacyQuestions.isNotEmpty) {
      _initializeFromQuestions(legacyQuestions);
    } else {
      _fetchQuestions();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(
          totalTimeSpent: DateTime.now().difference(_startTime),
        );
      }
    });
  }

  void _initializeFromQuestions(List<LessonQuestionData> legacy) {
    final list = legacy.map((q) {
      final dummyApiQuestion = MultipleChoiceQuestionResponse(
        id: '',
        question: q.question,
        choices: q.choices,
        correctAnswerIndex: q.choices.indexOf(q.correctAnswer),
      );
      return LessonQuestionState(
        apiQuestion: dummyApiQuestion,
      );
    }).toList();

    if (list.isNotEmpty) {
      list[0] = list[0].copyWith(startTime: DateTime.now());
    }

    state = state.copyWith(
      questions: list,
      isLoading: false,
    );
  }

  Future<void> _fetchQuestions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final apiClient = await _ref.read(apiClientProvider.future);
      final activitiesApi = ActivitiesApi(apiClient);
      final response = await activitiesApi.takeMultipleChoiceActivityApiV1ActivitiesPost();

      if (response == null || response.questions.isEmpty) {
        throw Exception('No questions available');
      }

      final list = response.questions.map((q) {
        return LessonQuestionState(apiQuestion: q);
      }).toList();

      if (list.isNotEmpty) {
        list[0] = list[0].copyWith(startTime: DateTime.now());
      }

      state = state.copyWith(
        questions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  void selectChoice(int index) {
    if (!state.isAnswerRevealed) {
      state = state.copyWith(selectedChoiceIndex: index);
    }
  }

  void submitAnswer() {
    if (state.selectedChoiceIndex == null) return;

    final currentIdx = state.currentQuestionIndex;
    final currentQuestion = state.questions[currentIdx];

    // Calculate time spent
    final int secondsSpent;
    if (currentQuestion.startTime != null) {
      secondsSpent = DateTime.now().difference(currentQuestion.startTime!).inSeconds.clamp(2, 3600);
    } else {
      secondsSpent = 2;
    }

    final isCorrect = state.selectedChoiceIndex == currentQuestion.apiQuestion.correctAnswerIndex;
    final newStatus = isCorrect ? LessonQuestionStatus.correct : LessonQuestionStatus.incorrect;

    final updatedQuestions = List<LessonQuestionState>.from(state.questions);
    updatedQuestions[currentIdx] = currentQuestion.copyWith(
      status: newStatus,
      studentAnswerIndex: state.selectedChoiceIndex,
      secondsSpent: secondsSpent,
    );

    state = state.copyWith(
      questions: updatedQuestions,
      isAnswerRevealed: true,
    );
  }

  Future<void> nextQuestion() async {
    final currentIdx = state.currentQuestionIndex;
    if (currentIdx < state.questions.length - 1) {
      // Go to next question
      final updatedQuestions = List<LessonQuestionState>.from(state.questions);
      updatedQuestions[currentIdx + 1] = updatedQuestions[currentIdx + 1].copyWith(
        startTime: DateTime.now(),
      );

      state = state.copyWith(
        questions: updatedQuestions,
        currentQuestionIndex: currentIdx + 1,
        selectedChoiceIndex: null,
        isAnswerRevealed: false,
      );
    } else {
      // Completed last question
      if (!state.isReviewMode && !_hasSubmittedAnswers) {
        await _submitEvaluation();
      } else {
        state = state.copyWith(isCompleted: true);
      }
    }
  }

  Future<void> _submitEvaluation() async {
    state = state.copyWith(isLoading: true);

    try {
      final apiClient = await _ref.read(apiClientProvider.future);
      final activitiesApi = ActivitiesApi(apiClient);

      final answers = state.questions
          .where((q) => q.studentAnswerIndex != null && q.secondsSpent != null)
          .map((q) => MultipleChoiceQuestionAnswer(
                id: q.apiQuestion.id,
                studentAnswerIndex: q.studentAnswerIndex!,
                secondsSpent: q.secondsSpent!,
              ))
          .toList();

      if (answers.isEmpty) {
        throw Exception('No answers to submit');
      }

      final request = MultipleChoiceActivityEvaluationRequest(answers: answers);
      final response = await activitiesApi.takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost(request);

      _hasSubmittedAnswers = true;
      state = state.copyWith(
        evaluationResponse: response,
        isLoading: false,
        isCompleted: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  void startReviewMode(List<LessonQuestionState> incorrectQuestions) {
    final list = incorrectQuestions.map((q) {
      return LessonQuestionState(
        apiQuestion: q.apiQuestion,
      );
    }).toList();

    if (list.isNotEmpty) {
      list[0] = list[0].copyWith(startTime: DateTime.now());
    }

    state = state.copyWith(
      questions: list,
      currentQuestionIndex: 0,
      selectedChoiceIndex: null,
      isAnswerRevealed: false,
      isReviewMode: true,
      isCompleted: false,
    );
  }

  int calculateLongestStreak() {
    int longestStreak = 0;
    int currentStreak = 0;

    for (var question in state.questions) {
      if (question.status == LessonQuestionStatus.correct) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
    }
    return longestStreak;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final lessonControllerProvider = StateNotifierProvider.autoDispose<LessonNotifier, LessonState>((ref) {
  return LessonNotifier(ref);
});
