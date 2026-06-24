import 'package:flutter/foundation.dart';

/// Base URL backend API — otomatis menyesuaikan platform.
class ApiConfig {
  // VPS via ngrok domain karena port 8080 diblokir NAT
  static const String _vpsUrl = 'https://scarabaeiform-darkly-laine.ngrok-free.dev';

  static String get baseUrl {
    if (kIsWeb) {
      // Web development: gunakan localhost
      return 'http://localhost:8080';
    }
    // Mobile / Desktop: gunakan VPS langsung
    return _vpsUrl;
  }
}
