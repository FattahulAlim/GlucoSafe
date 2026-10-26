import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _apiClient = ApiClient();
  final _storage = StorageService();

  Future<ApiResponse<User>> getProfile() async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<User>(
        success: false,
        message: 'Pengguna belum login.',
      );
    }

    final response = await _apiClient.get<User>(
      '${ApiConfig.usersPath}/me',
      token: token,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await _storage.saveUser(response.data!);
    }

    return response;
  }

  Future<ApiResponse<User>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<User>(
        success: false,
        message: 'Pengguna belum login.',
      );
    }

    final response = await _apiClient.put<User>(
      '${ApiConfig.usersPath}/me',
      {
        'name': name,
        'email': email,
      },
      token: token,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await _storage.saveUser(response.data!);
    }

    return response;
  }
}
