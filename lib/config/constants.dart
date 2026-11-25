import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Base URL del server locale.
  /// - Emulatore Android: http://10.0.2.2:8080
  /// - Web / Desktop: http://localhost:8080
  /// - Smartphone fisico in Wi-Fi: sostituisci con `http://<IP_DEL_TUO_PC>:8080`
  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}