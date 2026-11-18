class ApiConfig {
  static const String baseUrl =
      'https://backend-glucosafe-production.up.railway.app';

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
