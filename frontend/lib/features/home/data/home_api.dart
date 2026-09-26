import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_api.g.dart';

/// GET /home (`backend/api/v1/endpoints/home.py`), scoped by the backend to
/// the student's active goal.
class HomeApi {
  const HomeApi(this._api);

  final ApiClient _api;

  /// The detail the backend answers when the student has no active goal.
  static const noActiveGoal = 'No active goal';

  /// The dashboard, or null when the student has no active goal (404
  /// `No active goal`). Any other failure throws `ApiException`.
  Future<HomeDashboard?> fetch() async {
    try {
      final body = await _api.get('/home');
      return HomeDashboard.fromJson(body! as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status == 404 && e.detail == noActiveGoal) return null;
      rethrow;
    }
  }
}

@riverpod
HomeApi homeApi(Ref ref) => HomeApi(ref.watch(apiClientProvider));
