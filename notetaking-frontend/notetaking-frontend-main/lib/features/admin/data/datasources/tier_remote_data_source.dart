import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/tier_model.dart';

abstract class TierRemoteDataSource {
  Future<TierModel> getTier(int tierId);
  Future<List<TierModel>> getAllTiers();
  Future<TierModel> createTier(TierModel tier);
  Future<TierModel> updateTier(TierModel tier);
  Future<void> deleteTier(int tierId);
}

class TierRemoteDataSourceImpl implements TierRemoteDataSource {
  final Dio dio;

  TierRemoteDataSourceImpl({required this.dio});

  @override
  Future<TierModel> getTier(int tierId) async {
    try {
      final response = await dio.get('${AppConstants.adminTiersEndpoint}/$tierId');
      if (response.statusCode == 200) {
        return TierModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get tier');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<TierModel>> getAllTiers() async {
    try {
      final response = await dio.get(AppConstants.adminTiersEndpoint);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => TierModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get all tiers');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TierModel> createTier(TierModel tier) async {
    try {
      final response = await dio.post(
        AppConstants.adminTiersEndpoint,
        data: tier.toJson(),
      );
      if (response.statusCode == 201) {
        return TierModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create tier');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<TierModel> updateTier(TierModel tier) async {
    try {
      final response = await dio.patch(
        '${AppConstants.adminTiersEndpoint}/${tier.tierId}',
        data: tier.toJson(),
      );
      if (response.statusCode == 200) {
        return TierModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update tier');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> deleteTier(int tierId) async {
    try {
      final response = await dio.delete('${AppConstants.adminTiersEndpoint}/$tierId');
      if (response.statusCode != 204) {
        throw Exception('Failed to delete tier');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

