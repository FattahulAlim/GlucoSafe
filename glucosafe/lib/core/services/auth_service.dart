import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _apiClient = ApiClient();
  final _storage = StorageService();

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final response = await _apiClient.post<LoginResponse>(
      '${ApiConfig.authPath}/login',
      request.toJson(),
      fromJson: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await _storage.saveToken(response.data!.token);
      await _storage.saveUser(response.data!.user);
    }

    return response;
  }

  Future<ApiResponse<dynamic>> register(RegisterRequest request) async {
    return await _apiClient.post(
      '${ApiConfig.authPath}/register',
      request.toJson(),
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }
}
