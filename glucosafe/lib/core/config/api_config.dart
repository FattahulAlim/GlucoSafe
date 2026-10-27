import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // IP laptop di jaringan Wi-Fi untuk HP fisik:
      return 'http://192.168.1.8:3000';
      // Jika pakai Android Emulator, gunakan: 'http://10.0.2.2:3000'
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }

  static const String authPath = '/api/auth';
  static const String usersPath = '/api/users';
  static const String screeningsPath = '/api/screenings';

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> headersWithAuth(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
