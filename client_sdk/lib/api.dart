//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/achievements_api.dart';
part 'api/activities_api.dart';
part 'api/auth_api.dart';
part 'api/chat_api.dart';
part 'api/default_api.dart';
part 'api/goals_api.dart';
part 'api/objective_api.dart';
part 'api/onboarding_api.dart';
part 'api/resources_api.dart';
part 'api/streak_api.dart';
part 'api/student_api.dart';

part 'model/chat_message_item.dart';
part 'model/chat_message_response.dart';
part 'model/chat_message_response_item.dart';
part 'model/create_message_request.dart';
part 'model/create_message_request_item.dart';
part 'model/create_message_response.dart';
part 'model/edit_message_request.dart';
part 'model/goal_creation_follow_up_questions_request.dart';
part 'model/goal_creation_follow_up_questions_response.dart';
part 'model/goal_follow_up_question_and_answer.dart';
part 'model/goal_full_creation_request.dart';
part 'model/goal_list_item.dart';
part 'model/goal_study_plan_request.dart';
part 'model/goal_study_plan_response.dart';
part 'model/http_validation_error.dart';
part 'model/leaderboard_item.dart';
part 'model/leaderboard_response.dart';
part 'model/like_message_request.dart';
part 'model/list_goals_response.dart';
part 'model/multiple_choice_activity_evaluation_request.dart';
part 'model/multiple_choice_activity_evaluation_response.dart';
part 'model/multiple_choice_activity_response.dart';
part 'model/multiple_choice_question_answer.dart';
part 'model/multiple_choice_question_response.dart';
part 'model/o_auth2_request.dart';
part 'model/objective_item.dart';
part 'model/objective_list_response.dart';
part 'model/objective_note.dart';
part 'model/objective_response.dart';
part 'model/player_achievement_item.dart';
part 'model/player_achievement_response.dart';
part 'model/resource_item.dart';
part 'model/resource_response.dart';
part 'model/streak_day_response.dart';
part 'model/student_current_status_response.dart';
part 'model/student_response.dart';
part 'model/study_resource_type.dart';
part 'model/time_period_streak.dart';
part 'model/token_response.dart';
part 'model/validation_error.dart';
part 'model/validation_error_loc_inner.dart';
part 'model/xp_by_days_response.dart';
part 'model/xp_day.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
