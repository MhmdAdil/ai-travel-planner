import 'package:ai_travel_planner_frontend/features/discover/data/discover_activity_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty selection displays every category', () {
    expect(matchesDiscoverActivityFilters('Food', const {}), isTrue);
  });

  test('multiple selections display only matching activity groups', () {
    const selected = {'Temples', 'Beaches'};
    expect(matchesDiscoverActivityFilters('Temples', selected), isTrue);
    expect(matchesDiscoverActivityFilters('Beaches', selected), isTrue);
    expect(matchesDiscoverActivityFilters('Food', selected), isFalse);
  });

  test('grouped filters include related backend categories', () {
    expect(matchesDiscoverActivityFilters('History', const {'Museums & History'}), isTrue);
    expect(matchesDiscoverActivityFilters('Relaxation', const {'Nature & Parks'}), isTrue);
    expect(matchesDiscoverActivityFilters('Waterfalls', const {'Nature & Parks'}), isTrue);
    expect(matchesDiscoverActivityFilters('Water Sports', const {'Adventure & Viewpoints'}), isTrue);
    expect(matchesDiscoverActivityFilters('Shopping Malls', const {'Attractions'}), isTrue);
  });

  test('new nearby activity selections map to their exact OSM category', () {
    const expected = {
      'Waterfalls': 'Waterfalls',
      'Rivers': 'Rivers',
      'Ponds & Lakes': 'Ponds & Lakes',
      'Rocks & Caves': 'Rocks & Caves',
      'Mountains & Peaks': 'Mountains & Peaks',
      'Farms': 'Farms',
      'Forests': 'Forests',
      'Shopping Malls': 'Shopping Malls',
      'Water Parks': 'Water Parks',
      'Wildlife & Zoos': 'Wildlife',
      'Gardens': 'Gardens',
      'Camping & Picnics': 'Camping & Picnics',
      'Hiking & Trails': 'Hiking',
      'Cycling': 'Cycling',
      'Surfing & Water Sports': 'Water Sports',
      'Boating & Marinas': 'Boating & Marinas',
      'Sports & Recreation': 'Sports',
      'Cinemas & Theatres': 'Cinemas & Theatres',
      'Markets': 'Markets',
      'Playgrounds': 'Playgrounds',
      'Hot Springs': 'Hot Springs',
    };
    for (final entry in expected.entries) {
      expect(matchesDiscoverActivityFilters(entry.value, {entry.key}), isTrue);
      expect(matchesDiscoverActivityFilters('Food', {entry.key}), isFalse);
    }
  });
}
