import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kDebugMode) {
      // For local development with Docker Compose
      return 'http://localhost';
    } else {
      return 'https://revisit.com.br';
    }
  }
}
