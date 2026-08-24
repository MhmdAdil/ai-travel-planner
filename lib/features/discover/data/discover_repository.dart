import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'discover_exception.dart';
import 'models/map_route.dart';
import 'models/place.dart';

class DiscoverRepository {
  DiscoverRepository(this._apiService);

  final ApiService _apiService;

  Future<List<Place>> fetchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
    Set<String> activityFilters = const {},
  }) async {
    try {
      final response = await _apiService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        activityFilters: activityFilters,
      );
      final data = response.data;
      final list = data is Map<String, dynamic> ? data['places'] : data;
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map(Place.fromJson).toList();
      }
      throw const DiscoverException('The server returned an unexpected response.');
    } on DioException catch (e) {
      throw DiscoverException(_messageFor(e));
    }
  }

  Future<MapRoute> fetchDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await _apiService.getPlaceRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final route = MapRoute.fromJson(data);
        if (route.points.length >= 2) return route;
      }
      throw const DiscoverException('No road route was found for this place.');
    } on DioException catch (e) {
      throw DiscoverException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return 'Your login session expired. Open Profile, log out, and log in again.';
    }
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Could not reach the server. Check your connection and try again.';
      default:
        return 'Something went wrong while loading nearby places. Please try again.';
    }
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(ref.watch(apiServiceProvider));
});
