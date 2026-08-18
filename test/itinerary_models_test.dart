import 'package:ai_travel_planner_frontend/features/itinerary/data/models/itinerary.dart';
import 'package:ai_travel_planner_frontend/features/itinerary/data/models/trip_preference.dart';
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
      'generatorType': 'RULE_BASED_BASELINE',
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
            },
          ],
        },
      ],
    });

    expect(itinerary.days, hasLength(1));
    expect(itinerary.days.first.items.first.alternatives, ['Kandy Lake Walk']);
    expect(itinerary.costSummary.totalLkr, 30000);
    expect(itinerary.costSummary.totalUsd, 96.77);
  });
}
