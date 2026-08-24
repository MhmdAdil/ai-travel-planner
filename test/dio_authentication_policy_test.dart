import 'package:flutter_test/flutter_test.dart';

import 'package:ai_travel_planner_frontend/core/network/api_config.dart';
import 'package:ai_travel_planner_frontend/core/network/dio_client.dart';

void main() {
  test('Discover and route requests are not blocked by an expired token', () {
    expect(requiresAuthentication(ApiConfig.nearbyPlacesPath), isFalse);
    expect(requiresAuthentication(ApiConfig.placeRoutePath), isFalse);
  });

  test('private itinerary requests still require authentication', () {
    expect(requiresAuthentication(ApiConfig.generateItineraryPath), isTrue);
    expect(requiresAuthentication(ApiConfig.itinerariesPath), isTrue);
  });
}
