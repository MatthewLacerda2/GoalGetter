import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';

/// Exchange number [n]; a higher n is newer.
ChatExchange exchange(int n, {List<String>? responses, bool liked = false}) =>
    ChatExchange(
      id: 'e$n',
      prompt: 'prompt $n',
      responses: responses ?? ['reply $n.a', 'reply $n.b'],
      isLiked: liked,
      createdAt: '2026-09-21T10:00:00.${n.toString().padLeft(6, '0')}',
    );

/// A backend holding [stored] (oldest first) that pages like the real one.
/// A non-null error field makes that call throw it.
class FakeTutorApi implements TutorApi {
  FakeTutorApi(this.stored);

  final List<ChatExchange> stored;
  Object? listError;
  Object? sendError;
  Object? likeError;
  final List<String?> beforeCalls = [];

  @override
  Future<List<ChatExchange>> list({String? before, int limit = 20}) async {
    beforeCalls.add(before);
    if (listError != null) throw listError!;
    final older = stored
        .where((e) => before == null || e.createdAt.compareTo(before) < 0)
        .toList()
        .reversed;
    return older.take(limit).toList();
  }

  @override
  Future<ChatExchange> send(String message) async {
    if (sendError != null) throw sendError!;
    final created = ChatExchange(
      id: 'new',
      prompt: message,
      responses: const ['Ciao!', 'Pronto?'],
      isLiked: false,
      createdAt: '2026-09-21T11:00:00.000000',
    );
    stored.add(created);
    return created;
  }

  @override
  Future<ChatExchange> setLike(String id, bool isLiked) async {
    if (likeError != null) throw likeError!;
    return stored.firstWhere((e) => e.id == id).copyWith(isLiked: isLiked);
  }
}

const geminiDown = ApiException(503, 'The model is overloaded');
