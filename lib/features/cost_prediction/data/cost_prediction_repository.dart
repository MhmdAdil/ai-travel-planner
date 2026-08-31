import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'cost_prediction_exception.dart';
import 'models/cost_prediction.dart';

class CostPredictionRepository {
  CostPredictionRepository(this._apiService);

  final ApiService _apiService;

  Future<CostPrediction> predict(CostPredictionRequest request) async {
    try {
      final response = await _apiService.predictCost(request.toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CostPrediction.fromJson(data);
      }
      throw const CostPredictionException(
        'The cost prediction service returned an unexpected response.',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw CostPredictionException(data['message'] as String);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const CostPredictionException(
          'Could not reach the Spring backend for AI cost prediction.',
        );
      }
      throw const CostPredictionException(
        'AI cost prediction is temporarily unavailable. Check the XGBoost API and try again.',
      );
    }
  }
}

final costPredictionRepositoryProvider = Provider<CostPredictionRepository>((ref) {
  return CostPredictionRepository(ref.watch(apiServiceProvider));
});
