import 'package:flutter/foundation.dart';

class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8001',
  );
}
