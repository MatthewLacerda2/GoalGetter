import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lessons_api.g.dart';

/// The lesson endpoints (`backend/api/v1/endpoints/lessons.py`). Failures
/// surface as `ApiException`.
class LessonsApi {
  const LessonsApi(this._api);

  final ApiClient _api;

  /// 409 on [start]: the goal's question bank is still empty.
  static const notReadyStatus = 409;

  /// Opens a new lesson on [goalId]. Nothing is stored until [submit].
  Future<LessonSession> start(String goalId) async {
    final body = await _api.post('/goals/$goalId/lessons');
    return LessonSession.fromJson(body! as Map<String, dynamic>);
  }

  /// Sends the answers, all at once and in the order they were given; the
  /// server grades them and marks the batch as one lesson.
  Future<LessonEvaluation> submit(
    String goalId,
    List<LessonAnswer> answers,
  ) async {
    final body = await _api.post(
      '/goals/$goalId/lessons/answers',
      body: {'answers': answers.map((a) => a.toJson()).toList()},
    );
    return LessonEvaluation.fromJson(body! as Map<String, dynamic>);
  }
}

@riverpod
LessonsApi lessonsApi(LessonsApiRef ref) =>
    LessonsApi(ref.watch(apiClientProvider));
