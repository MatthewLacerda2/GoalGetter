import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kDebugMode) {
      return 'http://127.0.0.1:8000';
    } else {
      return 'https://your-cloud-api.com'; //TODO:Your actual cloud URL
    }
  }
}
