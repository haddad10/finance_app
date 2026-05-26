import 'package:flutter/foundation.dart';

/// Base URL backend API — otomatis menyesuaikan platform.
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    
    // Jika running di Windows (Desktop), gunakan localhost
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:8080';
    }

    // Android Emulator: http://10.0.2.2:8080
    // Physical Device: Gunakan IP lokal laptop (saat ini: 10.60.22.129)
    // Silakan ganti IP di bawah jika IP laptop Anda berubah
    return 'http://192.168.1.11:8080';
  }
}
