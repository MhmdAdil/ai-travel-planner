import 'package:flutter_test/flutter_test.dart';

import 'package:ai_travel_planner_frontend/features/cost_prediction/data/models/cost_prediction.dart';

void main() {
  test('serializes Spring cost prediction request using camelCase fields', () {
    const request = CostPredictionRequest(
      durationDays: 4,
      travellers: 2,
      budgetLkr: 120000,
      budgetLevel: 'LOW',
      accommodationType: 'Budget hotel',
      foodPreference: 'Sri Lankan',
      transportMode: 'Public transport',
      pace: 'Balanced',
      regionCount: 2,
      regionCostIndex: 1.12,
      publicTransportCoverage: 0.40,
      publicTransportKm: 400,
      privateTransportKm: 600,
      publicTransportCostLkr: 6200,
      privateTransportCostLkr: 59025,
      calculatedTransportCostLkr: 65225,
      placeCount: 7,
      activityCount: 5,
      hasBeach: true,
      hasCulture: true,
      hasWildlife: true,
      hasNature: false,
      hasHistory: false,
      hasAdventure: false,
      hasHiking: false,
      hasSurfing: true,
      hasSafari: true,
      hasSwimming: false,
      hasCycling: false,
      hasFoodTour: false,
      hasShopping: false,
      routeDistanceKm: 420,
      estimatedTravelHours: 11.5,
      nights: 3,
      rooms: 1,
    );

    final json = request.toJson();

    expect(json['durationDays'], 4);
    expect(json['budgetLevel'], 'LOW');
    expect(json['hasSurfing'], isTrue);
    expect(json['routeDistanceKm'], 420);
    expect(json.containsKey('duration_days'), isFalse);
  });

  test('parses Spring XGBoost prediction response', () {
    final result = CostPrediction.fromJson({
      'accommodationCostLkr': 36077.18,
      'foodCostLkr': 31702.89,
      'transportCostLkr': 65225.0,
      'publicTransportKm': 400.0,
      'privateTransportKm': 600.0,
      'publicTransportCostLkr': 6200.0,
      'privateTransportCostLkr': 59025.0,
      'activitiesCostLkr': 41642.33,
      'totalPredictedCostLkr': 123308.08,
      'userBudgetLkr': 120000.0,
      'budgetDifferenceLkr': -3308.08,
      'withinBudget': false,
      'model': 'XGBoost',
    });

    expect(result.totalPredictedCostLkr, closeTo(123308.08, 0.01));
    expect(result.withinBudget, isFalse);
    expect(result.model, 'XGBoost');
  });
}
