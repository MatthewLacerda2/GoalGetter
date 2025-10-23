import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kDebugMode) {
      return 'https://revisit.com.br';
    } else {
      return 'https://revisit.com.br';//TODO:Your actual cloud URL
    }
  }
}
