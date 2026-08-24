import 'package:ai_travel_planner_frontend/features/discover/data/models/map_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses route points in latitude-longitude order', () {
    final route = MapRoute.fromJson({
      'points': [
        {'latitude': 6.9271, 'longitude': 79.8612},
        {'latitude': 6.9300, 'longitude': 79.8700},
      ],
      'distanceKm': 1.4,
      'durationMinutes': 6,
    });

    expect(route.points, hasLength(2));
    expect(route.points.first.latitude, 6.9271);
    expect(route.points.first.longitude, 79.8612);
    expect(route.distanceKm, 1.4);
    expect(route.durationMinutes, 6);
  });
}
