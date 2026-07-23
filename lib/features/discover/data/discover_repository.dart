import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'discover_exception.dart';
import 'models/place.dart';

class DiscoverRepository {
  DiscoverRepository(this._apiService);

  final ApiService _apiService;

  Future<List<Place>> fetchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      final response = await _apiService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
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

  String _messageFor(DioException e) {
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
