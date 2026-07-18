import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'dio_client.dart';

class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> login({
    required String email,
    required String password,
  }) {
    return _dio.post(
      ApiConfig.loginPath,
      data: {'email': email, 'password': password},
    );
  }

  Future<Response<dynamic>> register({
    required String email,
    required String password,
  }) {
    return _dio.post(
      ApiConfig.registerPath,
      data: {'email': email, 'password': password},
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});
