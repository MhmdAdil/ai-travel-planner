import 'dart:math' as math;

import '../../itinerary/data/models/itinerary.dart';
import '../../itinerary/data/models/trip_preference.dart';
import 'models/cost_prediction.dart';

class CostPredictionInputBuilder {
  CostPredictionInputBuilder._();

  static CostPredictionRequest fromItinerary({
    required TripPreference preference,
    required Itinerary itinerary,
  }) {
    final allItems = itinerary.days.expand((day) => day.items).toList(growable: false);
    final routeDistanceKm =
        allItems.fold<double>(0, (sum, item) => sum + math.max(0, item.distanceKm));
    final travelMinutes =
        allItems.fold<int>(0, (sum, item) => sum + math.max(0, item.travelMinutes));

    final transport = _calculateTransport(
      items: allItems,
      strategy: preference.transportMode,
      budgetLevel: preference.budgetLevel,
      travellers: preference.groupSize,
    );

    final placeItems = allItems.where((item) {
      final category = item.category.toLowerCase();
      return !category.contains('accommodation') &&
          !category.contains('airport') &&
          !category.contains('transfer');
    }).toList(growable: false);

    final activityItems = placeItems.where((item) {
      final category = item.category.toLowerCase();
      return !category.contains('transport');
    }).toList(growable: false);

    return CostPredictionRequest(
      durationDays: preference.durationDays,
      travellers: preference.groupSize,
      budgetLkr: preference.budgetLkr,
      budgetLevel: _budgetLevel(preference.budgetLevel),
      accommodationType: _accommodationType(preference.accommodationType),
      foodPreference: _foodPreference(preference.foodPreference),
      transportMode: _transportMode(preference.transportMode),
      pace: _pace(preference.pace),
      regionCount: math.max(1, preference.travelRegions.length),
      regionCostIndex: _regionCostIndex(preference.travelRegions),
      publicTransportCoverage: transport.coverage,
      publicTransportKm: transport.publicKm,
      privateTransportKm: transport.privateKm,
      publicTransportCostLkr: transport.publicCostLkr,
      privateTransportCostLkr: transport.privateCostLkr,
      calculatedTransportCostLkr: transport.totalCostLkr,
      placeCount: math.max(1, placeItems.length),
      activityCount: math.max(preference.activities.length, activityItems.length),
      hasBeach: _contains(preference.interests, 'beach'),
      hasCulture: _contains(preference.interests, 'culture') ||
          _contains(preference.interests, 'temple') ||
          _contains(preference.interests, 'heritage'),
      hasWildlife: _contains(preference.interests, 'wildlife'),
      hasNature: _contains(preference.interests, 'nature') ||
          _contains(preference.interests, 'waterfall') ||
          _contains(preference.interests, 'forest'),
      hasHistory: _contains(preference.interests, 'history') ||
          _contains(preference.interests, 'heritage'),
      hasAdventure: _contains(preference.interests, 'adventure'),
      hasHiking: _contains(preference.activities, 'hiking'),
      hasSurfing: _contains(preference.activities, 'surfing'),
      hasSafari: _contains(preference.activities, 'safari'),
      hasSwimming: _contains(preference.activities, 'swimming'),
      hasCycling: _contains(preference.activities, 'cycling'),
      hasFoodTour: _contains(preference.activities, 'food tour'),
      hasShopping: _contains(preference.activities, 'shopping'),
      routeDistanceKm: routeDistanceKm,
      estimatedTravelHours: travelMinutes / 60.0,
      nights: math.max(0, preference.durationDays - 1),
      rooms: math.max(1, (preference.groupSize + 1) ~/ 2),
    );
  }

  static bool _contains(Iterable<String> values, String token) {
    final lowerToken = token.toLowerCase();
    return values.any((value) => value.toLowerCase().contains(lowerToken));
  }

  static String _budgetLevel(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'LOW' => 'LOW',
      'HIGH' => 'HIGH',
      _ => 'MID',
    };
  }

  static String _accommodationType(String value) => value.trim();

  static String _foodPreference(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('sri lankan')) return 'Sri Lankan';
    if (normalized.contains('seafood') || normalized.contains('international')) {
      return 'Cafe/Restaurant';
    }
    return 'Mixed';
  }

  static String _transportMode(String value) => value.trim();

  static _TransportCalculation _calculateTransport({
    required Iterable<ItineraryItem> items,
    required String strategy,
    required String budgetLevel,
    required int travellers,
  }) {
    final normalizedStrategy = strategy.toLowerCase();
    final normalizedBudget = budgetLevel.trim().toUpperCase();
    final usesPublic = normalizedStrategy.contains('public transport');
    final privateDriver = normalizedStrategy.contains('private driver');

    final publicShare = privateDriver || !usesPublic
        ? 0.0
        : switch (normalizedBudget) {
            'LOW' => 0.80,
            'HIGH' => 0.20,
            _ => 0.50,
          };
    final privateShare = 1.0 - publicShare;

    var publicKm = 0.0;
    var privateKm = 0.0;
    var publicCost = 0.0;
    var privateCost = 0.0;

    for (final item in items) {
      final distance = math.max(0.0, item.distanceKm);
      if (distance <= 0) continue;

      final publicDistance = distance * publicShare;
      final privateDistance = distance * privateShare;

      if (publicDistance > 0) {
        publicKm += publicDistance;
        final publicOption = _cheapestPublicOption(item);
        if (publicOption != null) {
          publicCost +=
              math.max(0.0, publicOption.estimatedFareLkr) * publicShare;
        } else {
          publicCost += _fallbackPublicFare(
            distanceKm: publicDistance,
            travellers: travellers,
          );
        }
      }

      if (privateDistance > 0) {
        privateKm += privateDistance;
        privateCost += _privateLegFare(
          distanceKm: privateDistance,
          strategy: strategy,
          travellers: travellers,
        );
      }
    }

    final totalKm = publicKm + privateKm;
    return _TransportCalculation(
      publicKm: publicKm,
      privateKm: privateKm,
      publicCostLkr: publicCost,
      privateCostLkr: privateCost,
      coverage: totalKm <= 0 ? 0 : publicKm / totalKm,
    );
  }

  static double _fallbackPublicFare({
    required double distanceKm,
    required int travellers,
  }) {
    if (distanceKm <= 0) return 0;
    const minimumFare = 40.0;
    const perKm = 6.5;
    final perPassenger =
        minimumFare + math.max(0.0, distanceKm - 1.0) * perKm;
    return perPassenger * math.max(1, travellers);
  }

  static TransportOption? _cheapestPublicOption(ItineraryItem item) {
    TransportOption? selected;
    for (final option in item.transportOptions) {
      final type = option.type.toLowerCase();
      final isPublic = type.contains('train') || type.contains('bus');
      if (!isPublic || option.estimatedFareLkr <= 0) continue;
      if (selected == null ||
          option.estimatedFareLkr < selected.estimatedFareLkr) {
        selected = option;
      }
    }
    return selected;
  }

  static double _privateLegFare({
    required double distanceKm,
    required String strategy,
    required int travellers,
  }) {
    final normalized = strategy.toLowerCase();
    final privateDriver = normalized.contains('private driver');

    var vehicle = 'car';
    var vehicleCount = 1;

    if (normalized.contains('2 minivans')) {
      vehicle = 'minivan';
      vehicleCount = 2;
    } else if (normalized.contains('2 vans')) {
      vehicle = 'van';
      vehicleCount = 2;
    } else if (normalized.contains('minivan')) {
      vehicle = 'minivan';
    } else if (normalized.contains('van')) {
      vehicle = 'van';
    } else if (normalized.contains('tuk/taxi')) {
      // Tuk capacity is 1-3. Four travellers are costed as a car.
      vehicle = travellers <= 3 ? 'tuk' : 'car';
    } else if (normalized.contains('tuk')) {
      vehicle = 'tuk';
    } else if (normalized.contains('car')) {
      vehicle = 'car';
    } else {
      // Defensive fallback based on traveller capacity.
      if (travellers <= 3) {
        vehicle = 'tuk';
      } else if (travellers <= 4) {
        vehicle = 'car';
      } else if (travellers <= 7) {
        vehicle = 'minivan';
      } else if (travellers <= 15) {
        vehicle = 'van';
      } else {
        vehicle = 'van';
        vehicleCount = 2;
      }
    }

    if (privateDriver) {
      final perKm = switch (vehicle) {
        'tuk' => 100.0,
        'car' => 140.0,
        'minivan' => 190.0,
        _ => 250.0,
      };
      return distanceKm * perKm * vehicleCount;
    }

    final startFare = switch (vehicle) {
      'tuk' => 200.0,
      'car' => 450.0,
      'minivan' => 800.0,
      _ => 1500.0,
    };
    // Midpoint of the user-supplied per-kilometre ranges.
    final additionalPerKm = switch (vehicle) {
      'tuk' => 80.0,       // 70-90
      'car' => 97.5,       // 85-110
      'minivan' => 120.0,  // 110-130
      _ => 175.0,          // 150-200
    };

    final oneVehicleFare =
        startFare + math.max(0.0, distanceKm - 1.0) * additionalPerKm;
    return oneVehicleFare * vehicleCount;
  }

  static double _regionCostIndex(Iterable<String> regions) {
    if (regions.isEmpty) return 1.0;
    const values = <String, double>{
      'Western Province': 1.18,
      'Southern Province': 1.20,
      'Upcountry / Central Highlands': 1.08,
      'Cultural Triangle / North Central': 1.05,
      'Eastern Province': 1.02,
      'Northern Province': 1.00,
      'North Western Province': 1.03,
      'Uva Province': 1.02,
      'Sabaragamuwa Province': 1.00,
    };
    final selected = regions.map((region) => values[region] ?? 1.0).toList();
    return selected.reduce((a, b) => a + b) / selected.length;
  }

  static String _pace(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('relax')) return 'Relaxed';
    if (normalized.contains('fast')) return 'Fast';
    return 'Balanced';
  }
}


class _TransportCalculation {
  const _TransportCalculation({
    required this.publicKm,
    required this.privateKm,
    required this.publicCostLkr,
    required this.privateCostLkr,
    required this.coverage,
  });

  final double publicKm;
  final double privateKm;
  final double publicCostLkr;
  final double privateCostLkr;
  final double coverage;

  double get totalCostLkr => publicCostLkr + privateCostLkr;
}
