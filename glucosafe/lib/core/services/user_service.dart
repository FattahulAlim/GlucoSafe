import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
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
      return ApiResponse<User>(success: false, message: 'Pengguna belum login.');
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

  Future<ApiResponse<User>> updateProfile({required String name, required String email}) async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<User>(success: false, message: 'Pengguna belum login.');
    }

    final response = await _apiClient.put<User>(
      '${ApiConfig.usersPath}/me',
      {'name': name, 'email': email},
      token: token,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await _storage.saveUser(response.data!);
    }
    return response;
  }

  Future<ApiResponse<dynamic>> changePassword(ChangePasswordRequest request) async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<dynamic>(success: false, message: 'Pengguna belum login.');
    }

    return await _apiClient.post<dynamic>(
      '${ApiConfig.usersPath}/me/password',
      request.toJson(),
      token: token,
    );
  }

  Future<ApiResponse<User>> uploadPhoto(File imageFile) async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<User>(success: false, message: 'Pengguna belum login.');
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersPath}/me/photo');
      final request = http.MultipartRequest('PUT', url);
      
      request.headers.addAll(ApiConfig.headersWithAuth(token));
      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Setelah upload sukses, ambil profil terbaru
        return await getProfile(); 
      } else {
        final jsonResponse = jsonDecode(response.body);
        return ApiResponse<User>(success: false, message: jsonResponse['message'] ?? 'Gagal upload foto');
      }
    } catch (e) {
      return ApiResponse<User>(success: false, message: 'Error upload: ${e.toString()}');
    }
  }

  Future<ApiResponse<dynamic>> deletePhoto() async {
    final token = await _storage.getToken();
    if (token == null) {
      return ApiResponse<dynamic>(success: false, message: 'Pengguna belum login.');
    }

    final response = await _apiClient.delete<dynamic>(
      '${ApiConfig.usersPath}/me/photo',
      token: token,
    );

    if (response.success) {
      await getProfile(); // Refresh data
    }
    return response;
  }
}