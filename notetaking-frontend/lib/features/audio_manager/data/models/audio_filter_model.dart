import '../../domain/entities/audio_filter.dart';

class AudioFilterModel extends AudioFilter {
  const AudioFilterModel({
    super.search,
    super.fromDate,
    super.toDate,
    super.hasTranscript,
    super.hasSummary,
    super.order,
    super.page,
    super.limit,
    super.status,
  });

  Map<String, dynamic> toSearchBody() {
    final resolvedOrder = order.isEmpty ? 'DESC' : order;
    final params = <String, dynamic>{
      'order': resolvedOrder,
      'page': page,
      'page_size': limit,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (fromDate != null) {
      params['from_date'] = fromDate!.toIso8601String();
    }
    if (toDate != null) {
      params['to_date'] = toDate!.toIso8601String();
    }
    if (hasTranscript != null) {
      params['has_transcript'] = hasTranscript;
    }
    if (hasSummary != null) {
      params['has_summary'] = hasSummary;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }

    return params;
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (fromDate != null) {
      params['from_date'] = fromDate!.toIso8601String();
    }
    if (toDate != null) {
      params['to_date'] = toDate!.toIso8601String();
    }

    return params;
  }
}
