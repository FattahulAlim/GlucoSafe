import '../../../core/network/api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<void> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      'auth/login',
      body: {'email': email, 'password': password},
    );
    final data = response['data'];
    final token = data is Map<String, dynamic> ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        'Token login tidak ditemukan pada respons server.',
      );
    }
    await _apiClient.saveToken(token);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      'auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
  }
}
