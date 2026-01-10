import 'package:dio/dio.dart';
import '../models/system_config_model.dart';

abstract class SystemConfigRemoteDataSource {
  Future<SystemConfigModel> getConfig(String configKey);
  Future<List<SystemConfigModel>> getAllConfigs();
  Future<SystemConfigModel> updateConfig(SystemConfigModel config);
}

class SystemConfigRemoteDataSourceImpl implements SystemConfigRemoteDataSource {
  final Dio dio;

  SystemConfigRemoteDataSourceImpl({required this.dio});

  @override
  Future<SystemConfigModel> getConfig(String configKey) async {
    try {
      final response = await dio.get('/admin/config/$configKey');
      if (response.statusCode == 200) {
        return SystemConfigModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get config');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<SystemConfigModel>> getAllConfigs() async {
    try {
      final response = await dio.get('/admin/config');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => SystemConfigModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get all configs');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<SystemConfigModel> updateConfig(SystemConfigModel config) async {
    try {
      final response = await dio.put(
        '/admin/config/${config.configKey}',
        data: config.toJson(),
      );
      if (response.statusCode == 200) {
        return SystemConfigModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update config');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

