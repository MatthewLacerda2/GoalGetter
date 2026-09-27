import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_api.g.dart';

/// GET /home (`backend/api/v1/endpoints/home.py`), scoped by the backend to
/// the student's active goal.
class HomeApi {
  const HomeApi(this._api);

  final ApiClient _api;

  /// The dashboard, or null when the student has no active goal
  /// ([ErrorCode.noActiveGoal]). Any other failure throws an `ApiFailure`.
  Future<HomeDashboard?> fetch() async {
    try {
      return await _api.send(
        ApiRoute.home,
        (json) => HomeDashboard.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.code == ErrorCode.noActiveGoal) return null;
      rethrow;
    }
  }
}

@riverpod
HomeApi homeApi(Ref ref) => HomeApi(ref.watch(apiClientProvider));
