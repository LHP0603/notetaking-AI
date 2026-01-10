import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/system_config_model.dart';

abstract class SystemConfigLocalDataSource {
  Future<void> cacheConfig(SystemConfigModel config);
  Future<SystemConfigModel?> getCachedConfig(String configKey);
  Future<List<SystemConfigModel>> getCachedConfigs();
  Future<void> clearCache();
}

class SystemConfigLocalDataSourceImpl implements SystemConfigLocalDataSource {
  final SharedPreferences sharedPreferences;

  SystemConfigLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheConfig(SystemConfigModel config) async {
    await sharedPreferences.setString(
      'system_config_${config.configKey}',
      jsonEncode(config.toJson()),
    );
  }

  @override
  Future<SystemConfigModel?> getCachedConfig(String configKey) async {
    final jsonString = sharedPreferences.getString('system_config_$configKey');
    if (jsonString != null) {
      return SystemConfigModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<List<SystemConfigModel>> getCachedConfigs() async {
    final keys = sharedPreferences.getKeys().where(
      (key) => key.startsWith('system_config_'),
    );
    final configs = <SystemConfigModel>[];
    for (final key in keys) {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString != null) {
        configs.add(SystemConfigModel.fromJson(jsonDecode(jsonString)));
      }
    }
    return configs;
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys().where(
      (key) => key.startsWith('system_config_'),
    );
    for (final key in keys) {
      await sharedPreferences.remove(key);
    }
  }
}

