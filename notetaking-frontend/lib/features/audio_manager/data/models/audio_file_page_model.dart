import '../../domain/entities/audio_file_page.dart';
import 'audio_file_model.dart';

class AudioFilePageModel extends AudioFilePage {
  const AudioFilePageModel({
    required super.items,
    required super.total,
    required super.page,
    required super.limit,
    super.hasNextPage,
  });

  factory AudioFilePageModel.fromJson(Map<String, dynamic> json) {
    int? _intFrom(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool? _boolFrom(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        if (value.toLowerCase() == 'true') {
          return true;
        }
        if (value.toLowerCase() == 'false') {
          return false;
        }
      }
      return null;
    }

    final rawItems = json['items'] ?? json['data'];
    final items =
        (rawItems is List ? rawItems : const <dynamic>[])
            .map(
              (item) => AudioFileModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

    final meta = json['meta'] as Map<String, dynamic>?;
    final total =
        _intFrom(json['total']) ??
        _intFrom(meta?['item_count']) ??
        items.length;
    final page =
        _intFrom(json['page']) ?? _intFrom(meta?['page']) ?? 1;
    final limit =
        _intFrom(json['limit']) ?? _intFrom(meta?['page_size']) ?? items.length;
    final hasNextPage =
        _boolFrom(json['has_next_page']) ??
        _boolFrom(meta?['has_next_page']);

    return AudioFilePageModel(
      items: items,
      total: total,
      page: page,
      limit: limit,
      hasNextPage: hasNextPage,
    );
  }
}
