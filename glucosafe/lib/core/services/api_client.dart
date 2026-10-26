import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<ApiResponse<T>> post<T>(
    String path,
    Map<String, dynamic> body, {
    T Function(dynamic)? fromJson,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = token != null
          ? ApiConfig.headersWithAuth(token)
          : ApiConfig.headers;

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<T>.fromJson(jsonResponse, fromJson);
      } else {
        return ApiResponse<T>(
          success: false,
          message: jsonResponse['message'] as String? ?? 'Terjadi kesalahan',
        );
      }
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException {
      return ApiResponse<T>(
        success: false,
        message: 'Gagal menghubungi server.',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(dynamic)? fromJson,
    String? token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = token != null
          ? ApiConfig.headersWithAuth(token)
          : ApiConfig.headers;

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<T>.fromJson(jsonResponse, fromJson);
      } else {
        return ApiResponse<T>(
          success: false,
          message: jsonResponse['message'] as String? ?? 'Terjadi kesalahan',
        );
      }
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException {
      return ApiResponse<T>(
        success: false,
        message: 'Gagal menghubungi server.',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }
}
