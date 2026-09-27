/// Every backend operation the app calls: its HTTP method and its path under
/// `/api/v1`, written exactly as the backend's OpenAPI writes it —
/// placeholders included (`/goals/{goal_id}`).
///
/// `ApiClient` sends nothing else, so this list is every call the app can
/// make, complete by construction. `test/contract/api_contract_test.dart`
/// checks each entry against the committed snapshot of the backend's API
/// (`backend/openapi.json`): a route the backend renamed or removed
/// fails `make frontend`, not the app.
enum ApiRoute {
  signup('POST', '/auth/signup'),

  /// Served only when the backend runs with `DEV_LOGIN=true`, and hidden from
  /// its schema otherwise, so the snapshot — which is production's — does not
  /// have it.
  devLogin('POST', '/auth/dev-login', devOnly: true),
  refresh('POST', '/auth/refresh'),
  logout('POST', '/auth/logout'),
  objectiveQuestions('POST', '/goals/objective-questions'),
  studyPlan('POST', '/goals/study-plan'),
  createGoal('POST', '/goals'),
  listGoals('GET', '/goals'),
  standardAnswers('POST', '/goals/{goal_id}/standard-answers'),
  setActiveGoal('PUT', '/goals/{goal_id}/set-active'),
  deleteGoal('DELETE', '/goals/{goal_id}'),
  home('GET', '/home'),
  startLesson('POST', '/goals/{goal_id}/lessons'),
  submitLesson('POST', '/goals/{goal_id}/lessons/answers'),
  me('GET', '/me'),
  resources('GET', '/resources'),
  tutorMessages('GET', '/tutor/messages'),
  sendTutorMessage('POST', '/tutor/messages'),
  likeTutorMessage('PUT', '/tutor/messages/{message_id}/like');

  const ApiRoute(this.method, this.template, {this.devOnly = false});

  final String method;
  final String template;
  final bool devOnly;

  static final _placeholder = RegExp(r'\{(\w+)\}');

  /// The placeholders in [template], in order.
  List<String> get params =>
      [for (final m in _placeholder.allMatches(template)) m.group(1)!];

  /// [template] with each placeholder replaced by its value in [values],
  /// URI-encoded. A placeholder without a value, or a value without a
  /// placeholder, is a programming error and throws [ArgumentError].
  String path([Map<String, String> values = const {}]) {
    final missing = params.where((p) => !values.containsKey(p));
    final extra = values.keys.where((k) => !params.contains(k));
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw ArgumentError.value(values, 'values', '$template takes $params');
    }
    return template.replaceAllMapped(
      _placeholder,
      (m) => Uri.encodeComponent(values[m.group(1)]!),
    );
  }
}
