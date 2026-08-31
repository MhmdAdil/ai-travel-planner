class CostPredictionRequest {
  const CostPredictionRequest({
    required this.durationDays,
    required this.travellers,
    required this.budgetLkr,
    required this.budgetLevel,
    required this.accommodationType,
    required this.foodPreference,
    required this.transportMode,
    required this.pace,
    required this.regionCount,
    required this.regionCostIndex,
    required this.publicTransportCoverage,
    required this.publicTransportKm,
    required this.privateTransportKm,
    required this.publicTransportCostLkr,
    required this.privateTransportCostLkr,
    required this.calculatedTransportCostLkr,
    required this.placeCount,
    required this.activityCount,
    required this.hasBeach,
    required this.hasCulture,
    required this.hasWildlife,
    required this.hasNature,
    required this.hasHistory,
    required this.hasAdventure,
    required this.hasHiking,
    required this.hasSurfing,
    required this.hasSafari,
    required this.hasSwimming,
    required this.hasCycling,
    required this.hasFoodTour,
    required this.hasShopping,
    required this.routeDistanceKm,
    required this.estimatedTravelHours,
    required this.nights,
    required this.rooms,
  });

  final int durationDays;
  final int travellers;
  final double budgetLkr;
  final String budgetLevel;
  final String accommodationType;
  final String foodPreference;
  final String transportMode;
  final String pace;
  final int regionCount;
  final double regionCostIndex;
  final double publicTransportCoverage;
  final double publicTransportKm;
  final double privateTransportKm;
  final double publicTransportCostLkr;
  final double privateTransportCostLkr;
  final double calculatedTransportCostLkr;
  final int placeCount;
  final int activityCount;
  final bool hasBeach;
  final bool hasCulture;
  final bool hasWildlife;
  final bool hasNature;
  final bool hasHistory;
  final bool hasAdventure;
  final bool hasHiking;
  final bool hasSurfing;
  final bool hasSafari;
  final bool hasSwimming;
  final bool hasCycling;
  final bool hasFoodTour;
  final bool hasShopping;
  final double routeDistanceKm;
  final double estimatedTravelHours;
  final int nights;
  final int rooms;

  Map<String, dynamic> toJson() => {
        'durationDays': durationDays,
        'travellers': travellers,
        'budgetLkr': budgetLkr,
        'budgetLevel': budgetLevel,
        'accommodationType': accommodationType,
        'foodPreference': foodPreference,
        'transportMode': transportMode,
        'pace': pace,
        'regionCount': regionCount,
        'regionCostIndex': regionCostIndex,
        'publicTransportCoverage': publicTransportCoverage,
        'publicTransportKm': publicTransportKm,
        'privateTransportKm': privateTransportKm,
        'publicTransportCostLkr': publicTransportCostLkr,
        'privateTransportCostLkr': privateTransportCostLkr,
        'calculatedTransportCostLkr': calculatedTransportCostLkr,
        'placeCount': placeCount,
        'activityCount': activityCount,
        'hasBeach': hasBeach,
        'hasCulture': hasCulture,
        'hasWildlife': hasWildlife,
        'hasNature': hasNature,
        'hasHistory': hasHistory,
        'hasAdventure': hasAdventure,
        'hasHiking': hasHiking,
        'hasSurfing': hasSurfing,
        'hasSafari': hasSafari,
        'hasSwimming': hasSwimming,
        'hasCycling': hasCycling,
        'hasFoodTour': hasFoodTour,
        'hasShopping': hasShopping,
        'routeDistanceKm': routeDistanceKm,
        'estimatedTravelHours': estimatedTravelHours,
        'nights': nights,
        'rooms': rooms,
      };

  String get fingerprint => [
        durationDays,
        travellers,
        budgetLkr.toStringAsFixed(0),
        budgetLevel,
        accommodationType,
        foodPreference,
        transportMode,
        pace,
        regionCount,
        regionCostIndex.toStringAsFixed(3),
        publicTransportCoverage.toStringAsFixed(3),
        publicTransportKm.toStringAsFixed(2),
        privateTransportKm.toStringAsFixed(2),
        publicTransportCostLkr.toStringAsFixed(0),
        privateTransportCostLkr.toStringAsFixed(0),
        calculatedTransportCostLkr.toStringAsFixed(0),
        placeCount,
        activityCount,
        hasBeach,
        hasCulture,
        hasWildlife,
        hasNature,
        hasHistory,
        hasAdventure,
        hasHiking,
        hasSurfing,
        hasSafari,
        hasSwimming,
        hasCycling,
        hasFoodTour,
        hasShopping,
        routeDistanceKm.toStringAsFixed(2),
        estimatedTravelHours.toStringAsFixed(2),
        nights,
        rooms,
      ].join('|');
}

class CostPrediction {
  const CostPrediction({
    required this.accommodationCostLkr,
    required this.foodCostLkr,
    required this.transportCostLkr,
    required this.publicTransportKm,
    required this.privateTransportKm,
    required this.publicTransportCostLkr,
    required this.privateTransportCostLkr,
    required this.activitiesCostLkr,
    required this.totalPredictedCostLkr,
    required this.userBudgetLkr,
    required this.budgetDifferenceLkr,
    required this.withinBudget,
    required this.model,
  });

  final double accommodationCostLkr;
  final double foodCostLkr;
  final double transportCostLkr;
  final double publicTransportKm;
  final double privateTransportKm;
  final double publicTransportCostLkr;
  final double privateTransportCostLkr;
  final double activitiesCostLkr;
  final double totalPredictedCostLkr;
  final double userBudgetLkr;
  final double budgetDifferenceLkr;
  final bool withinBudget;
  final String model;

  factory CostPrediction.fromJson(Map<String, dynamic> json) => CostPrediction(
        accommodationCostLkr: _number(json['accommodationCostLkr']),
        foodCostLkr: _number(json['foodCostLkr']),
        transportCostLkr: _number(json['transportCostLkr']),
        publicTransportKm: _number(json['publicTransportKm']),
        privateTransportKm: _number(json['privateTransportKm']),
        publicTransportCostLkr: _number(json['publicTransportCostLkr']),
        privateTransportCostLkr: _number(json['privateTransportCostLkr']),
        activitiesCostLkr: _number(json['activitiesCostLkr']),
        totalPredictedCostLkr: _number(json['totalPredictedCostLkr']),
        userBudgetLkr: _number(json['userBudgetLkr']),
        budgetDifferenceLkr: _number(json['budgetDifferenceLkr']),
        withinBudget: json['withinBudget'] as bool? ?? false,
        model: json['model'] as String? ?? 'XGBoost',
      );
}

double _number(Object? value) => (value as num?)?.toDouble() ?? 0;
