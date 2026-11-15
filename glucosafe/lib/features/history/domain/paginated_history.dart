/// Model informasi pagination dari API backend.
class PaginationInfo {
  final int page;
  final int limit;
  final int? total;
  final bool hasMore;

  const PaginationInfo({
    required this.page,
    required this.limit,
    this.total,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        if (total != null) 'total': total,
        'hasMore': hasMore,
      };
}
