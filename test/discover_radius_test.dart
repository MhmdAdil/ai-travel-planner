import 'package:ai_travel_planner_frontend/features/discover/application/discover_state.dart';
import 'package:ai_travel_planner_frontend/features/discover/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Place place(String id, double distanceKm) => Place(
      id: id,
      name: id,
      category: 'Food',
      description: '',
      averageCostLkr: null,
      averageCostUsd: null,
      feeStatus: 'UNKNOWN',
      feeDetails: '',
      address: '',
      openingHours: '',
      website: '',
      phone: '',
      latitude: 7.6,
      longitude: 79.9,
      distanceKm: distanceKm,
      dataSource: 'OPENSTREETMAP',
      sourceUrl: 'https://www.openstreetmap.org/node/1',
    );

void main() {
  test('visible places never include records outside selected radius', () {
    final state = DiscoverState(
      center: const LatLng(7.6091, 79.9751),
      radiusKm: 5,
      status: DiscoverStatus.loaded,
      selectedActivityFilters: const {'Food & Cafes'},
      places: [place('inside', 4.99), place('outside', 13.07)],
    );

    expect(state.visiblePlaces.map((item) => item.id), ['inside']);
  });
}
