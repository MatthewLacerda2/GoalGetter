import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/profile/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_api.g.dart';

/// GET /me (`backend/api/v1/endpoints/me.py`). Failures surface as
/// `ApiException`.
class ProfileApi {
  const ProfileApi(this._api);

  final ApiClient _api;

  Future<UserProfile> me() async {
    final body = await _api.get('/me');
    return UserProfile.fromJson(body! as Map<String, dynamic>);
  }
}

@riverpod
ProfileApi profileApi(Ref ref) =>
    ProfileApi(ref.watch(apiClientProvider));
