import '../config/api_config.dart';
import '../models/api_response.dart';
import '../../features/screening/domain/screening_form.dart';
import '../../features/screening/domain/screening_result.dart';
import 'api_client.dart';
import 'storage_service.dart';

class ScreeningService {
  static final ScreeningService _instance = ScreeningService._internal();
  factory ScreeningService() => _instance;
  ScreeningService._internal();

  final _apiClient = ApiClient();
  final _storage = StorageService();

  /// Melakukan prediksi hasil skrining via POST /api/screenings/predict (tanpa simpan ke DB)
  Future<ApiResponse<ScreeningResult>> predictScreening(ScreeningForm form) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse<ScreeningResult>(
        success: false,
        message: 'Pengguna belum login. Silakan login terlebih dahulu.',
      );
    }

    try {
      final payload = form.toBackendJson();
      return await _apiClient.post<ScreeningResult>(
        '${ApiConfig.screeningsPath}/predict',
        payload,
        token: token,
        fromJson: (json) => ScreeningResult.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse<ScreeningResult>(
        success: false,
        message: 'Gagal memproses prediksi: ${e.toString()}',
      );
    }
  }

  /// Menyimpan hasil skrining ke riwayat DB via POST /api/screenings
  Future<ApiResponse<ScreeningResult>> saveScreening({
    required ScreeningForm form,
    double? riskPercent,
    String? riskLabel,
  }) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse<ScreeningResult>(
        success: false,
        message: 'Pengguna belum login. Silakan login terlebih dahulu.',
      );
    }

    try {
      final payload = form.toBackendJson();
      if (riskPercent != null) payload['risk_percent'] = riskPercent;
      if (riskLabel != null) payload['risk_label'] = riskLabel;

      return await _apiClient.post<ScreeningResult>(
        ApiConfig.screeningsPath,
        payload,
        token: token,
        fromJson: (json) => ScreeningResult.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse<ScreeningResult>(
        success: false,
        message: 'Gagal menyimpan ke riwayat: ${e.toString()}',
      );
    }
  }

  /// Mengirim hasil skrining ke backend via POST /api/screenings
  Future<ApiResponse<ScreeningResult>> submitScreening(ScreeningForm form) async {
    return saveScreening(form: form);
  }

  /// Mengambil riwayat skrining pengguna via GET /api/screenings
  Future<ApiResponse<List<ScreeningResult>>> getHistory() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse<List<ScreeningResult>>(
        success: false,
        message: 'Pengguna belum login.',
      );
    }

    return await _apiClient.get<List<ScreeningResult>>(
      ApiConfig.screeningsPath,
      token: token,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => ScreeningResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  /// Mengambil detail skrining berdasarkan ID via GET /api/screenings/:id
  Future<ApiResponse<ScreeningResult>> getDetail(int id) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse<ScreeningResult>(
        success: false,
        message: 'Pengguna belum login.',
      );
    }

    return await _apiClient.get<ScreeningResult>(
      '${ApiConfig.screeningsPath}/$id',
      token: token,
      fromJson: (json) => ScreeningResult.fromJson(json as Map<String, dynamic>),
    );
  }
}

