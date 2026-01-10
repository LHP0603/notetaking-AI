import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/summary_model.dart';

abstract class SummaryLocalDataSource {
  Future<void> cacheSummary(String transcriptionId, SummaryModel summary);
  Future<SummaryModel?> getCachedSummary(String transcriptionId);
  Future<void> clearCache();
}

class SummaryLocalDataSourceImpl implements SummaryLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cachePrefix = 'CACHED_SUMMARY_';

  SummaryLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheSummary(String transcriptionId, SummaryModel summary) async {
    final key = '$_cachePrefix$transcriptionId';
    final jsonString = jsonEncode(summary.toJson());
    await sharedPreferences.setString(key, jsonString);
  }

  @override
  Future<SummaryModel?> getCachedSummary(String transcriptionId) async {
    final key = '$_cachePrefix$transcriptionId';
    final jsonString = sharedPreferences.getString(key);
    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SummaryModel.fromJson(json);
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}

