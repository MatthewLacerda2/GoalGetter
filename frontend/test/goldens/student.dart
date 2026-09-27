import 'dart:convert';

import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// The one student every golden shows: two goals, a week of lessons, a tutor
/// chat and a shelf of resources, as the backend would answer them. Every date
/// is fixed and naive (no zone), so a golden drawn here and one drawn on CI
/// read the same day and the same hour, whatever either clock says.
///
/// No image URL anywhere: a network image in a widget test fails
/// asynchronously, sometimes before the capture and sometimes after.

Map<String, Object> _goal(String id, String name, {required bool active}) =>
    {
      'id': id,
      'name': name,
      'description': 'Play a full game of **$name** without a blunder in the '
          'opening, and know why each move is played.',
      'current_elo': 1180,
      'is_active': active,
      'created_at': '2026-09-01T12:00:00',
      'updated_at': '2026-09-20T12:00:00',
    };

Map<String, Object> _lesson(String date, int accuracy, int seconds) => {
      'lesson_id': 'l-$date',
      'date': date,
      'accuracy': accuracy,
      'duration_seconds': seconds,
    };

Map<String, Object> _resource(String name, String description) => {
      'name': name,
      'description': description,
      'url': 'https://example.com/${Uri.encodeComponent(name)}',
    };

/// A lesson question whose right choice is the first.
Map<String, Object> _question(String id, String question, List<String> c) =>
    {'id': id, 'question': question, 'choices': c, 'correct_answer_index': 0};

final _goals = [
  _goal('g1', 'Chess', active: true),
  _goal('g2', 'Italian', active: false),
];

final _home = {
  'goal_name': 'Chess',
  'current_elo': 1180,
  'current_streak': 6,
  'recent_lessons': [
    _lesson('2026-09-21', 90, 212),
    _lesson('2026-09-20', 70, 305),
    _lesson('2026-09-19', 50, 184),
  ],
};

final _tutor = [
  {
    'id': 'e1',
    'prompt': 'What is a fork?',
    'responses': ['One piece attacking two at once: only one can be saved.'],
    'is_liked': true,
    'created_at': '2026-09-21T12:00:00.000000',
  },
];

final _resources = {
  'youtube': [
    _resource('Opening principles',
        'Ten minutes on the centre, development and castling.'),
  ],
  'books': [_resource('Logical Chess', 'Every move of 33 games, explained.')],
  'websites': [
    _resource('Lichess practice', 'Short drills on forks, pins and skewers.'),
  ],
};

/// Three questions: the review golden misses the second.
final _lessonBody = {
  'questions': [
    _question('q1', 'Which piece can jump over others?',
        ['Knight', 'Bishop', 'Rook', 'Queen']),
    _question('q2', 'Where does the king go when castling short?',
        ['g1', 'c1', 'e1', 'h1']),
    _question('q3', 'What is a pawn worth, in points?', ['1', '3', '5', '9']),
  ],
};

const _evaluation = {
  'total_seconds_spent': 272,
  'student_accuracy': 66.7,
  'elo': 14,
};

/// The student's replies, by `'<METHOD> <path>'` under /api/v1.
final Map<String, (int, String)> studentReplies = {
  'GET /goals': (200, jsonEncode(_goals)),
  'GET /home': (200, jsonEncode(_home)),
  'GET /tutor/messages': (200, jsonEncode(_tutor)),
  'GET /resources': (200, jsonEncode(_resources)),
  'POST /goals/g1/lessons': (201, jsonEncode(_lessonBody)),
  'POST /goals/g1/lessons/answers': (200, jsonEncode(_evaluation)),
};

const String goalPrompt = 'Learn chess well enough to beat my brother';

const goalQuestions = GoalQuestionsArgs(
  prompt: goalPrompt,
  questions: [
    ObjectiveQuestion(
      question: 'How well do you know the rules?',
      options: [
        'Not at all',
        'I know how the pieces move',
        'I play casually',
        'I play in a club',
      ],
      aiModel: 'gemini-3.8-flash',
    ),
    ObjectiveQuestion(
      question: 'How much time can you give it each day?',
      options: ['Under 15 minutes', '15 to 30', '30 to 60', 'Over an hour'],
      aiModel: 'gemini-3.8-flash',
    ),
  ],
);

const goalDraft = GoalDraft(
  prompt: goalPrompt,
  answers: [
    ObjectiveAnswer(
      question: 'How well do you know the rules?',
      answer: 'I know how the pieces move',
      aiModel: 'gemini-3.8-flash',
    ),
  ],
  plan: StudyPlan(
    goalName: 'Chess',
    description: 'You will start with **how the game opens**, then move on to'
        ' **tactics** and **simple endgames**.\n\nEach lesson is short and'
        ' builds on the last one.',
  ),
);

const standardQuestions = StandardQuestionsArgs(
  goalId: 'g1',
  questions: [
    StandardQuestion(
      key: 'age',
      optionKeys: ['under18', '18to24', '25to39', '40plus'],
    ),
    StandardQuestion(
      key: 'purpose',
      optionKeys: ['school', 'work', 'project', 'curiosity'],
    ),
  ],
);
