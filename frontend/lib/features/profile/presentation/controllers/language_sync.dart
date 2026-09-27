import 'package:goal_getter/features/profile/data/profile_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_sync.g.dart';

/// Tells the backend the language the student has just picked.
///
/// Any signed-in request carries `X-Student-Language` (ApiClient) and the
/// backend stores it (#172): one GET /me tells it the new language now rather
/// than on the next unrelated request. Best-effort — a failure only delays
/// that until the next request, and there is nothing to show: the picker has
/// already changed the app's language.
class LanguageSync {
  const LanguageSync(this._api);

  final ProfileApi _api;

  Future<void> tellBackend() async {
    try {
      await _api.me();
    } on Exception {
      // See the class: nothing to show.
    }
  }
}

@riverpod
LanguageSync languageSync(Ref ref) =>
    LanguageSync(ref.watch(profileApiProvider));
