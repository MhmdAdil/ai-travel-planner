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
    required String username,
    required String email,
    required String password,
  }) {
    return _dio.post(
      ApiConfig.registerPath,
      data: {'username': username, 'email': email, 'password': password},
    );
  }

  Future<Response<dynamic>> generateItinerary(
    Map<String, dynamic> preferences,
  ) {
    return _dio.post(
      ApiConfig.generateItineraryPath,
      data: preferences,
    );
  }

  Future<Response<dynamic>> predictCost(Map<String, dynamic> request) {
    return _dio.post(
      ApiConfig.costPredictionPath,
      data: request,
    );
  }

  Future<Response<dynamic>> getSavedItineraries() {
    return _dio.get(ApiConfig.itinerariesPath);
  }

  Future<Response<dynamic>> getNearbyPlaces({
    required double lat,
    required double lng,
    required double radiusKm,
    Set<String> activityFilters = const {},
  }) {
    return _dio.get(
      ApiConfig.nearbyPlacesPath,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
        if (activityFilters.isNotEmpty) 'activities': activityFilters.join(','),
      },
    );
  }

  Future<Response<dynamic>> getPlaceRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return _dio.get(
      ApiConfig.placeRoutePath,
      queryParameters: {
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
      },
    );
  }

  Future<Response<dynamic>> getProfile() {
    return _dio.get(ApiConfig.profilePath);
  }

  Future<Response<dynamic>> updateUsername(String username) {
    return _dio.patch(
      ApiConfig.profileUsernamePath,
      data: {'username': username},
    );
  }

  Future<Response<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _dio.patch(
      ApiConfig.profilePasswordPath,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<Response<dynamic>> sendChatMessage(Map<String, dynamic> payload) {
    return _dio.post(
      ApiConfig.chatMessagePath,
      data: payload,
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});
