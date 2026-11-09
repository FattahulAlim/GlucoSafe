import '../../../core/network/api_client.dart';

class HistoryService {
  HistoryService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _apiClient.get('screenings/history');
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('Format data riwayat dari server tidak valid.');
    }

    return data.map((record) {
      if (record is! Map<String, dynamic>) {
        throw const ApiException('Format salah satu data riwayat tidak valid.');
      }
      return record;
    }).toList();
  }
}
