import 'package:ai_travel_planner_frontend/features/cost_prediction/data/cost_prediction_input_builder.dart';
import 'package:ai_travel_planner_frontend/features/itinerary/data/models/itinerary.dart';
import 'package:ai_travel_planner_frontend/features/itinerary/data/models/trip_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LOW mixed transport is 80 public / 20 private', () {
    final request = _build('LOW', 'Public transport + Car - Uber/PickMe');
    expect(request.publicTransportKm, closeTo(80, 0.001));
    expect(request.privateTransportKm, closeTo(20, 0.001));
    expect(request.publicTransportCoverage, closeTo(0.80, 0.001));
  });

  test('MID mixed transport is 50 public / 50 private', () {
    final request = _build('MID', 'Public transport + Car - Uber/PickMe');
    expect(request.publicTransportKm, closeTo(50, 0.001));
    expect(request.privateTransportKm, closeTo(50, 0.001));
    expect(request.publicTransportCoverage, closeTo(0.50, 0.001));
  });

  test('HIGH mixed transport is 20 public / 80 private', () {
    final request = _build('HIGH', 'Public transport + Car - Uber/PickMe');
    expect(request.publicTransportKm, closeTo(20, 0.001));
    expect(request.privateTransportKm, closeTo(80, 0.001));
    expect(request.publicTransportCoverage, closeTo(0.20, 0.001));
  });

  test('Uber PickMe only is 100 percent private', () {
    final request = _build('MID', 'Car - Uber/PickMe');
    expect(request.publicTransportKm, 0);
    expect(request.privateTransportKm, closeTo(100, 0.001));
    expect(request.publicTransportCostLkr, 0);
  });

  test('private driver is 100 percent private driver price', () {
    final request = _build('HIGH', 'Private driver + Car');
    expect(request.publicTransportKm, 0);
    expect(request.privateTransportKm, closeTo(100, 0.001));
    expect(request.privateTransportCostLkr, closeTo(14000, 0.001));
  });
}

dynamic _build(String budgetLevel, String transportMode) {
  final preference = TripPreference(
    destinationRegion: 'Kandy',
    startLocation: 'Colombo',
    arrivalDateTime: DateTime(2026, 8, 28, 8),
    departureDateTime: DateTime(2026, 8, 28, 20),
    budgetLevel: budgetLevel,
    budgetLkr: 200000,
    groupSize: 2,
    travelRegions: const ['Central Province'],
    interests: const ['Culture'],
    activities: const ['Heritage sightseeing'],
    accommodationType: 'Mid-range hotel / 3-star',
    foodPreference: 'Sri Lankan',
    transportMode: transportMode,
    pace: 'Balanced',
    returnToAirport: false,
  );

  const item = ItineraryItem(
    startTime: '08:00',
    endTime: '12:00',
    name: 'Test destination',
    category: 'Culture',
    description: '',
    location: 'Kandy',
    travelMinutes: 180,
    visitMinutes: 120,
    distanceKm: 100,
    estimatedCostLkr: 0,
    estimatedCostUsd: 0,
    alternatives: [],
    transportOptions: [
      TransportOption(
        type: 'Bus',
        vehicleModel: 'Public bus',
        serviceName: 'Test public service',
        capacity: 45,
        estimatedMinutes: 180,
        estimatedFareLkr: 2000,
        fareNote: '',
        source: 'TEST',
      ),
    ],
    latitude: 7.29,
    longitude: 80.63,
    dataSource: 'TEST',
    sourceReference: null,
    sourceUrl: null,
  );

  final itinerary = Itinerary(
    id: 1,
    title: 'Test trip',
    destinationRegion: 'Kandy',
    generatorType: 'TEST',
    providerNote: '',
    destinationLatitude: 7.29,
    destinationLongitude: 80.63,
    costSummary: const CostSummary(
      accommodationLkr: 0,
      foodLkr: 0,
      transportLkr: 0,
      activitiesLkr: 0,
      totalLkr: 0,
      totalUsd: 0,
      budgetLkr: 200000,
      withinBudget: true,
      budgetDifferenceLkr: 200000,
      lkrPerUsd: 310,
      rateNote: '',
    ),
    days: [
      ItineraryDay(
        dayNumber: 1,
        date: DateTime(2026, 8, 28),
        theme: '',
        estimatedCostLkr: 0,
        estimatedCostUsd: 0,
        items: const [item],
      ),
    ],
  );

  return CostPredictionInputBuilder.fromItinerary(
    preference: preference,
    itinerary: itinerary,
  );
}
