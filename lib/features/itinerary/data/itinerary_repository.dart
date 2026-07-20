import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'itinerary_exception.dart';
import 'models/itinerary.dart';
import 'models/trip_preference.dart';

class ItineraryRepository {
  ItineraryRepository(this._apiService);

  final ApiService _apiService;

  Future<Itinerary> generate(TripPreference preference) async {
    try {
      final response = await _apiService.generateItinerary(preference.toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Itinerary.fromJson(data);
      }
      throw const ItineraryException('The server returned an unexpected response.');
    } on DioException catch (e) {
      throw ItineraryException(_messageFor(e));
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
        return 'Something went wrong while generating your itinerary. Please try again.';
    }
  }
}

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository(ref.watch(apiServiceProvider));
});
