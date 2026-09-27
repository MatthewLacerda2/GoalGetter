import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tutor_api.g.dart';

/// `/tutor/messages`, scoped by the backend to the student's active goal: a
/// student without one gets 404 `No active goal` from every call.
class TutorApi {
  TutorApi(this._api);

  final ApiClient _api;

  static const pageSize = 20;

  /// The detail the backend answers when the student has no active goal.
  static const noActiveGoal = 'No active goal';

  /// Newest first. [before] is the oldest loaded exchange's `createdAt`.
  Future<List<ChatExchange>> list({
    String? before,
    int limit = pageSize,
  }) async {
    final query = Uri(
      queryParameters: {
        if (before != null) 'before': before,
        'limit': '$limit',
      },
    ).query;
    return _api.get(
      '/tutor/messages?$query',
      (json) => [
        for (final e in json! as List)
          ChatExchange.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  /// Calls Gemini on the backend; a Gemini failure keeps its status code.
  Future<ChatExchange> send(String message) => _api.post(
        '/tutor/messages',
        _exchange,
        body: {'message': message},
      );

  /// Sets (not toggles) the like on the exchange's reply.
  Future<ChatExchange> setLike(String id, bool isLiked) => _api.put(
        '/tutor/messages/$id/like',
        _exchange,
        body: {'is_liked': isLiked},
      );

  static ChatExchange _exchange(Object? json) =>
      ChatExchange.fromJson(json! as Map<String, dynamic>);
}

@riverpod
TutorApi tutorApi(Ref ref) => TutorApi(ref.watch(apiClientProvider));
