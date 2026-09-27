import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tutor_api.g.dart';

/// `/tutor/messages`, scoped by the backend to the student's active goal: a
/// student without one gets `no_active_goal` from every call.
class TutorApi {
  TutorApi(this._api);

  final ApiClient _api;

  static const pageSize = 20;

  /// Newest first. [before] is the oldest loaded exchange's `createdAt`.
  Future<List<ChatExchange>> list({
    String? before,
    int limit = pageSize,
  }) async {
    return _api.send(
      ApiRoute.tutorMessages,
      (json) => [
        for (final e in json! as List)
          ChatExchange.fromJson(e as Map<String, dynamic>),
      ],
      query: {
        if (before != null) 'before': before,
        'limit': '$limit',
      },
    );
  }

  /// Calls Gemini on the backend; a Gemini failure keeps its status code.
  Future<ChatExchange> send(String message) => _api.send(
        ApiRoute.sendTutorMessage,
        _exchange,
        body: {'message': message},
      );

  /// Sets (not toggles) the like on the exchange's reply.
  Future<ChatExchange> setLike(String id, bool isLiked) => _api.send(
        ApiRoute.likeTutorMessage,
        _exchange,
        params: {'message_id': id},
        body: {'is_liked': isLiked},
      );

  static ChatExchange _exchange(Object? json) =>
      ChatExchange.fromJson(json! as Map<String, dynamic>);
}

@riverpod
TutorApi tutorApi(Ref ref) => TutorApi(ref.watch(apiClientProvider));
