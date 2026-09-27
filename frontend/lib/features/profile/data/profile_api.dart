import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_api.g.dart';

/// GET /me (`backend/api/v1/endpoints/me.py`). Failures surface as an
/// `ApiFailure`.
///
/// Nothing shows the profile; the call exists for its request header. Every
/// signed-in request carries `X-Student-Language` and the backend stores it,
/// so the profile calls this right after the
/// student picks a language.
class ProfileApi {
  const ProfileApi(this._api);

  final ApiClient _api;

  Future<void> me() => _api.send(ApiRoute.me, ApiClient.ignoreBody);
}

@riverpod
ProfileApi profileApi(Ref ref) =>
    ProfileApi(ref.watch(apiClientProvider));
