class CostSummary {
  const CostSummary({
    required this.accommodationLkr,
    required this.foodLkr,
    required this.transportLkr,
    required this.activitiesLkr,
    required this.totalLkr,
    required this.totalUsd,
    required this.budgetLkr,
    required this.withinBudget,
    required this.budgetDifferenceLkr,
    required this.lkrPerUsd,
    required this.rateNote,
  });

  final double accommodationLkr;
  final double foodLkr;
  final double transportLkr;
  final double activitiesLkr;
  final double totalLkr;
  final double totalUsd;
  final double budgetLkr;
  final bool withinBudget;
  final double budgetDifferenceLkr;
  final double lkrPerUsd;
  final String rateNote;

  factory CostSummary.fromJson(Map<String, dynamic> json) => CostSummary(
        accommodationLkr: _number(json['accommodationLkr']),
        foodLkr: _number(json['foodLkr']),
        transportLkr: _number(json['transportLkr']),
        activitiesLkr: _number(json['activitiesLkr']),
        totalLkr: _number(json['totalLkr']),
        totalUsd: _number(json['totalUsd']),
        budgetLkr: _number(json['budgetLkr']),
        withinBudget: json['withinBudget'] as bool? ?? false,
        budgetDifferenceLkr: _number(json['budgetDifferenceLkr']),
        lkrPerUsd: _number(json['lkrPerUsd']),
        rateNote: json['rateNote'] as String? ?? 'Approximate USD conversion.',
      );
}

class ItineraryItem {
  const ItineraryItem({
    required this.startTime,
    required this.endTime,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.travelMinutes,
    required this.distanceKm,
    required this.estimatedCostLkr,
    required this.estimatedCostUsd,
    required this.alternatives,
    required this.latitude,
    required this.longitude,
    required this.dataSource,
    required this.sourceReference,
    required this.sourceUrl,
  });

  final String startTime;
  final String endTime;
  final String name;
  final String category;
  final String description;
  final String location;
  final int travelMinutes;
  final double distanceKm;
  final double estimatedCostLkr;
  final double estimatedCostUsd;
  final List<String> alternatives;
  final double? latitude;
  final double? longitude;
  final String dataSource;
  final String? sourceReference;
  final String? sourceUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
        startTime: json['startTime']?.toString() ?? '',
        endTime: json['endTime']?.toString() ?? '',
        name: json['name'] as String? ?? 'Unknown place',
        category: json['category'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
        location: json['location'] as String? ?? '',
        travelMinutes: (json['travelMinutes'] as num?)?.toInt() ?? 0,
        distanceKm: _number(json['distanceKm']),
        estimatedCostLkr: _number(json['estimatedCostLkr']),
        estimatedCostUsd: _number(json['estimatedCostUsd']),
        alternatives: (json['alternatives'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        latitude: _nullableNumber(json['latitude']),
        longitude: _nullableNumber(json['longitude']),
        dataSource: json['dataSource'] as String? ?? 'UNKNOWN',
        sourceReference: json['sourceReference'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
      );
}

class ItineraryDay {
  ItineraryDay({
    required this.dayNumber,
    required this.date,
    required this.theme,
    required this.estimatedCostLkr,
    required this.estimatedCostUsd,
    required List<ItineraryItem> items,
  }) : items = List.unmodifiable(items);

  final int dayNumber;
  final DateTime? date;
  final String theme;
  final double estimatedCostLkr;
  final double estimatedCostUsd;
  final List<ItineraryItem> items;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final itemsJson =
        json['items'] as List<dynamic>? ?? json['places'] as List<dynamic>? ?? const [];
    return ItineraryDay(
      dayNumber:
          (json['dayNumber'] as num?)?.toInt() ?? (json['day'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      theme: json['theme'] as String? ?? '',
      estimatedCostLkr: _number(json['estimatedCostLkr']),
      estimatedCostUsd: _number(json['estimatedCostUsd']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(ItineraryItem.fromJson)
          .toList(),
    );
  }

  ItineraryDay withoutItemAt(int index) => ItineraryDay(
        dayNumber: dayNumber,
        date: date,
        theme: theme,
        estimatedCostLkr: estimatedCostLkr,
        estimatedCostUsd: estimatedCostUsd,
        items: [for (var i = 0; i < items.length; i++) if (i != index) items[i]],
      );
}

class Itinerary {
  Itinerary({
    required this.id,
    required this.title,
    required this.destinationRegion,
    required this.generatorType,
    required this.providerNote,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.costSummary,
    required List<ItineraryDay> days,
  }) : days = List.unmodifiable(days);

  final int id;
  final String title;
  final String destinationRegion;
  final String generatorType;
  final String providerNote;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final CostSummary costSummary;
  final List<ItineraryDay> days;

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? const [];
    return Itinerary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Your trip',
      destinationRegion: json['destinationRegion'] as String? ?? '',
      generatorType: json['generatorType'] as String? ?? 'UNKNOWN',
      providerNote: json['providerNote'] as String? ??
          'Saved itinerary using the development place catalogue.',
      destinationLatitude: _nullableNumber(json['destinationLatitude']),
      destinationLongitude: _nullableNumber(json['destinationLongitude']),
      costSummary: CostSummary.fromJson(
        json['costSummary'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      days: daysJson
          .whereType<Map<String, dynamic>>()
          .map(ItineraryDay.fromJson)
          .toList(),
    );
  }

  Itinerary withItemRemoved({required int dayIndex, required int itemIndex}) => Itinerary(
        id: id,
        title: title,
        destinationRegion: destinationRegion,
        generatorType: generatorType,
        providerNote: providerNote,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        costSummary: costSummary,
        days: [
          for (var i = 0; i < days.length; i++)
            if (i == dayIndex) days[i].withoutItemAt(itemIndex) else days[i],
        ],
      );
}

double _number(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _nullableNumber(Object? value) => (value as num?)?.toDouble();
