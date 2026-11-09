import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();

  factory ApiClient({http.Client? client, FlutterSecureStorage? storage}) {
    if (client == null && storage == null) return instance;
    return ApiClient._(client: client, storage: storage);
  }

  ApiClient._({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Uri _uri(String path) {
    final defaultHost = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    final baseUrl = _configuredBaseUrl.isEmpty
        ? 'http://$defaultHost:3000/api'
        : _configuredBaseUrl;

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl/$path');
  }

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) {
    return _request('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?>? body,
    bool authenticated = false,
  }) {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } on PlatformException catch (error) {
      throw ApiException(
        error.message ?? 'Token autentikasi gagal disimpan dengan aman.',
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    if (authenticated) {
      final String? token;
      try {
        token = await _storage.read(key: _tokenKey);
      } on PlatformException catch (error) {
        throw ApiException(
          error.message ?? 'Token autentikasi gagal dibaca dari penyimpanan.',
        );
      }
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Sesi login tidak ditemukan. Silakan masuk kembali.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamedResponse);
    } on http.ClientException catch (error) {
      throw ApiException('Tidak dapat terhubung ke server: ${error.message}');
    } on TimeoutException {
      throw const ApiException('Permintaan ke server melewati batas waktu.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'Respons server tidak valid (${response.statusCode}).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Format respons server tidak valid.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] == false) {
      final message = decoded['message'];
      throw ApiException(
        message is String && message.isNotEmpty
            ? message
            : 'Permintaan gagal (${response.statusCode}).',
      );
    }

    return decoded;
  }
}
