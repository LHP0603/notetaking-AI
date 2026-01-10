import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/folder_model.dart';

abstract class FolderRemoteDataSource {
  Future<FolderModel> createFolder({
    required String name,
    String? parentFolderId,
  });
  Future<List<FolderModel>> getFolders({String? parentFolderId});
  Future<FolderModel> updateFolder({
    required String folderId,
    String? name,
    String? parentFolderId,
  });
  Future<void> deleteFolder(String folderId);
}

class FolderRemoteDataSourceImpl implements FolderRemoteDataSource {
  final Dio dio;

  FolderRemoteDataSourceImpl({required this.dio});

  @override
  Future<FolderModel> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    try {
      final data = <String, dynamic>{'name': name};
      // Only include parent_folder_id if it's not null
      if (parentFolderId != null) {
        data['parent_folder_id'] = parentFolderId;
      }
      
      final response = await dio.post(
        AppConstants.foldersEndpoint,
        data: data,
      );
      if (response.statusCode == 201) {
        return FolderModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create folder: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = e.response!.data?.toString() ?? e.message ?? 'Unknown error';
        throw Exception('Failed to create folder ($statusCode): $errorMessage');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<FolderModel>> getFolders({String? parentFolderId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (parentFolderId != null)
        queryParams['parent_folder_id'] = parentFolderId;

      final response = await dio.get(
        AppConstants.foldersEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => FolderModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get folders');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<FolderModel> updateFolder({
    required String folderId,
    String? name,
    String? parentFolderId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (parentFolderId != null) data['parent_folder_id'] = parentFolderId;

      final response = await dio.patch(
        '${AppConstants.foldersEndpoint.replaceAll(RegExp(r'/$'), '')}/$folderId',
        data: data,
      );
      if (response.statusCode == 200) {
        return FolderModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update folder');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    try {
      final response = await dio.delete(
        '${AppConstants.foldersEndpoint.replaceAll(RegExp(r'/$'), '')}/$folderId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete folder');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

