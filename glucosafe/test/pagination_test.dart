import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/core/models/api_response.dart';
import 'package:glucosafe/features/history/domain/paginated_history.dart';

void main() {
  group('PaginationInfo & ApiResponse Pagination Tests', () {
    test('parses pagination info correctly', () {
      final json = {'page': 2, 'limit': 20, 'total': 45, 'hasMore': true};

      final pagination = PaginationInfo.fromJson(json);
      expect(pagination.page, 2);
      expect(pagination.limit, 20);
      expect(pagination.total, 45);
      expect(pagination.hasMore, isTrue);
    });

    test('handles default pagination info when fields are missing', () {
      final json = <String, dynamic>{};

      final pagination = PaginationInfo.fromJson(json);
      expect(pagination.page, 1);
      expect(pagination.limit, 20);
      expect(pagination.hasMore, isFalse);
    });

    test('ApiResponse parses pagination payload', () {
      final json = {
        'success': true,
        'message': 'Riwayat screening berhasil diambil.',
        'data': [
          {'id': 1},
        ],
        'pagination': {'page': 1, 'limit': 20, 'hasMore': true},
      };

      final response = ApiResponse<List<dynamic>>.fromJson(
        json,
        (data) => data as List<dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.pagination, isNotNull);
      expect(response.pagination!['page'], 1);
      expect(response.pagination!['hasMore'], isTrue);

      final paginationInfo = PaginationInfo.fromJson(response.pagination!);
      expect(paginationInfo.page, 1);
      expect(paginationInfo.hasMore, isTrue);
    });
  });
}
