import 'dart:convert';

import 'package:goal_getter/core/api/error_code.dart';

/// An error body as the backend writes it (#214): the contract check
/// (`contract_client.dart`) rejects a 4xx or 5xx fixture without a code.
String errorBody(ErrorCode code, [String detail = 'for the log']) =>
    jsonEncode({'code': code.wire, 'detail': detail});

/// A crash: a 500 that names no cause.
final crashed = errorBody(ErrorCode.internalError);

/// What a fake backend answers a request the test gave it no reply for.
final noRoute = errorBody(ErrorCode.routeNotFound);
