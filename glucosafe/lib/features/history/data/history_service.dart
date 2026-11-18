import '../../../core/config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';

class HistoryService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<ApiResponse<List<Map<String, dynamic>>>> getHistory({
    int? page,
    int? limit,
  }) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Pengguna belum login.',
      );
    }

    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;

    return _apiClient.get<List<Map<String, dynamic>>>(
      '${ApiConfig.screeningsPath}/history',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      token: token,
      fromJson: (json) {
        if (json is! List) {
          throw const FormatException('Format data riwayat tidak valid.');
        }
        return json.map((record) {
          if (record is! Map<String, dynamic>) {
            throw const FormatException(
              'Format salah satu riwayat tidak valid.',
            );
          }
          return record;
        }).toList();
      },
    );
  }
}
