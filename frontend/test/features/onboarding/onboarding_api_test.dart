import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_onboarding_api.dart';

/// An [OnboardingApi] on a backend answering [body] with [status]; the sent
/// requests land in [sent].
Future<OnboardingApi> apiAnswering(
  Object body,
  List<http.Request> sent, {
  int status = 200,
}) async {
  SharedPreferences.setMockInitialValues({});
  final client = MockClient((request) async {
    sent.add(request);
    return http.Response(jsonEncode(body), status);
  });
  return OnboardingApi(
    ApiClient(
      httpClient: client,
      storage: SettingsStorage(await SharedPreferences.getInstance()),
      baseUrl: 'http://api.test',
    ),
  );
}

void main() {
  test('objective questions read question and four options', () async {
    final sent = <http.Request>[];
    final api = await apiAnswering([
      {
        'question': 'Q?',
        'options': ['a', 'b', 'c', 'd'],
      },
    ], sent);
    final questions = await api.objectiveQuestions('Learn Italian');
    expect(questions.single.options, ['a', 'b', 'c', 'd']);
    expect(sent.single.url.path, '/api/v1/goals/objective-questions');
    expect(jsonDecode(sent.single.body), {'prompt': 'Learn Italian'});
  });

  test('a 400 carries the reasoning as the detail', () async {
    final api = await apiAnswering({'detail': 'Not a goal'}, [], status: 400);
    expect(
      api.objectiveQuestions('x'),
      throwsA(
        isA<ApiException>().having((e) => e.detail, 'detail', 'Not a goal'),
      ),
    );
  });

  test('create sends the approved plan and reads the standard questions', () async {
    final sent = <http.Request>[];
    final api = await apiAnswering(
      {
        'id': 'g1',
        'name': 'Travel Italian',
        'standard_questions': [
          {
            'key': 'age',
            'options': ['under18', '18to24', '25to39', '40plus'],
          },
        ],
      },
      sent,
      status: 201,
    );
    final goal = await api.create(draft);
    expect(goal.standardQuestions.single.key, 'age');
    expect(goal.standardQuestions.single.optionKeys.first, 'under18');
    expect(jsonDecode(sent.single.body), {
      'prompt': draft.prompt,
      'answers': [
        {'question': 'Level?', 'answer': 'None'},
      ],
      'goal_name': plan.goalName,
      'description': plan.description,
    });
  });

  test('the standard answers go to the goal that asked them', () async {
    final sent = <http.Request>[];
    final api = await apiAnswering('', sent, status: 204);

    await api.sendStandardAnswers('g1', const [
      StandardAnswer(questionKey: 'age', optionKey: '18to24'),
    ]);

    expect(sent.single.url.path, '/api/v1/goals/g1/standard-answers');
    expect(jsonDecode(sent.single.body), {
      'answers': [
        {'question_key': 'age', 'option_key': '18to24'},
      ],
    });
  });
}
