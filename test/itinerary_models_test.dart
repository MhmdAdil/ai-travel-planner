import 'package:ai_travel_planner_frontend/features/itinerary/data/models/itinerary.dart';
import 'package:ai_travel_planner_frontend/features/itinerary/data/models/trip_preference.dart';
import 'package:ai_travel_planner_frontend/features/discover/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trip preference serializes the complete planning request', () {
    final preference = TripPreference(
      destinationRegion: 'Kandy',
      startLocation: 'Bandaranaike International Airport',
      arrivalDateTime: DateTime(2030, 1, 10, 9),
      departureDateTime: DateTime(2030, 1, 12, 18),
      budgetLevel: 'MID',
      budgetLkr: 150000,
      groupSize: 2,
      interests: const ['Culture'],
      activities: const ['Hiking'],
      accommodationType: 'Mid-range hotel',
      foodPreference: 'Sri Lankan',
      transportMode: 'Public transport',
      pace: 'Balanced',
    );

    expect(preference.durationDays, 3);
    expect(preference.toJson()['budgetLevel'], 'MID');
    expect(preference.toJson()['arrivalDateTime'], '2030-01-10T09:00:00.000');
    expect(preference.toJson()['activities'], ['Hiking']);
  });

  test('itinerary parses day schedules, alternatives and dual currency costs', () {
    final itinerary = Itinerary.fromJson({
      'id': 10,
      'title': 'Kandy trip',
      'destinationRegion': 'Kandy',
      'generatorType': 'OPENSTREETMAP_LIVE',
      'providerNote': 'Live places from OpenStreetMap.',
      'destinationLatitude': 7.2906,
      'destinationLongitude': 80.6337,
      'costSummary': {
        'accommodationLkr': 18000,
        'foodLkr': 6500,
        'transportLkr': 2500,
        'activitiesLkr': 3000,
        'totalLkr': 30000,
        'totalUsd': 96.77,
        'budgetLkr': 100000,
        'withinBudget': true,
        'budgetDifferenceLkr': 70000,
        'lkrPerUsd': 310,
        'rateNote': 'Approximate',
      },
      'days': [
        {
          'dayNumber': 1,
          'date': '2030-01-10',
          'theme': 'Culture in Kandy',
          'estimatedCostLkr': 3000,
          'estimatedCostUsd': 9.68,
          'items': [
            {
              'startTime': '09:00:00',
              'endTime': '11:00:00',
              'name': 'Temple of the Sacred Tooth Relic',
              'category': 'Culture',
              'description': 'Visit a landmark.',
              'location': 'Kandy',
              'travelMinutes': 0,
              'distanceKm': 2,
              'estimatedCostLkr': 3000,
              'estimatedCostUsd': 9.68,
              'alternatives': ['Kandy Lake Walk'],
              'latitude': 7.2936,
              'longitude': 80.6413,
              'dataSource': 'OPENSTREETMAP',
              'sourceReference': 'node/123',
              'sourceUrl': 'https://www.openstreetmap.org/node/123',
            },
          ],
        },
      ],
    });

    expect(itinerary.days, hasLength(1));
    expect(itinerary.days.first.items.first.alternatives, ['Kandy Lake Walk']);
    expect(itinerary.costSummary.totalLkr, 30000);
    expect(itinerary.costSummary.totalUsd, 96.77);
    expect(itinerary.generatorType, 'OPENSTREETMAP_LIVE');
    expect(itinerary.days.first.items.first.hasCoordinates, isTrue);
    expect(itinerary.days.first.items.first.dataSource, 'OPENSTREETMAP');
  });

  test('nearby place parses live OSM evidence and fee status', () {
    final place = Place.fromJson({
      'id': 'node/123',
      'name': 'Kandy Viewpoint',
      'category': 'Adventure',
      'description': 'Live place',
      'averageCostLkr': null,
      'averageCostUsd': null,
      'feeStatus': 'UNKNOWN',
      'feeDetails': 'Cost information is not available from OpenStreetMap.',
      'address': 'Kandy',
      'openingHours': '08:00-18:00',
      'website': 'https://example.org',
      'phone': '+94 00 000 0000',
      'latitude': 7.30,
      'longitude': 80.64,
      'distanceKm': 1.4,
      'dataSource': 'OPENSTREETMAP',
      'sourceUrl': 'https://www.openstreetmap.org/node/123',
    });

    expect(place.name, 'Kandy Viewpoint');
    expect(place.averageCostLkr, isNull);
    expect(place.averageCostUsd, isNull);
    expect(place.feeStatus, 'UNKNOWN');
    expect(place.openingHours, '08:00-18:00');
    expect(place.distanceKm, 1.4);
    expect(place.dataSource, 'OPENSTREETMAP');
  });
}
