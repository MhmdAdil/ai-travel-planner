import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'auth_exception.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final ApiService _apiService;

  Future<String> login({required String email, required String password}) async {
    try {
      final response = await _apiService.login(email: email, password: password);
      final token = response.data is Map ? response.data['token'] as String? : null;
      if (token == null || token.isEmpty) {
        throw const AuthException('Login succeeded but no token was returned.');
      }
      return token;
    } on DioException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> register({required String email, required String password}) async {
    try {
      await _apiService.register(email: email, password: password);
    } on DioException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (e.response?.statusCode) {
      case 401:
        return 'Invalid email or password.';
      case 409:
        return 'An account with that email already exists.';
      default:
        return e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout
            ? 'Could not reach the server. Check your connection.'
            : 'Something went wrong. Please try again.';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});
