import 'package:ai_travel_planner_frontend/features/chat/data/chat_travel_context.dart';
import 'package:ai_travel_planner_frontend/features/itinerary/data/models/trip_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat context includes current trip preferences', () {
    final preference = TripPreference(
      destinationRegion: 'Kandy',
      startLocation: 'Colombo',
      arrivalDateTime: DateTime(2026, 8, 28, 8),
      departureDateTime: DateTime(2026, 8, 31, 18),
      budgetLevel: 'MID',
      budgetLkr: 180000,
      groupSize: 2,
      travelRegions: const ['Central Province'],
      interests: const ['Culture'],
      activities: const ['Heritage sightseeing'],
      accommodationType: 'Mid-range hotel / 3-star',
      foodPreference: 'Sri Lankan',
      transportMode: 'Public transport + Car - Uber/PickMe',
      pace: 'Balanced',
      returnToAirport: true,
    );

    final context = ChatTravelContextBuilder.build(preference: preference);

    expect(context, contains('Start location: Colombo'));
    expect(context, contains('Destination region: Kandy'));
    expect(context, contains('Budget: LKR 180000 (MID)'));
    expect(context, contains('Travellers: 2'));
    expect(context, contains('Finish at CMB airport: Yes'));
  });
}
