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


class TransportOption {
  const TransportOption({
    required this.type,
    required this.vehicleModel,
    required this.serviceName,
    required this.capacity,
    required this.estimatedMinutes,
    required this.estimatedFareLkr,
    required this.fareNote,
    required this.source,
  });

  final String type;
  final String vehicleModel;
  final String serviceName;
  final int capacity;
  final int estimatedMinutes;
  final double estimatedFareLkr;
  final String fareNote;
  final String source;

  factory TransportOption.fromJson(Map<String, dynamic> json) => TransportOption(
        type: json['type'] as String? ?? 'Transport',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        serviceName: json['serviceName'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
        estimatedFareLkr: _number(json['estimatedFareLkr']),
        fareNote: json['fareNote'] as String? ?? '',
        source: json['source'] as String? ?? '',
      );
}

class AlternativePlace {
  const AlternativePlace({
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.travelMinutes,
    required this.visitMinutes,
    required this.distanceKm,
    required this.estimatedCostLkr,
    required this.estimatedCostUsd,
    required this.transportOptions,
    required this.latitude,
    required this.longitude,
    required this.dataSource,
    required this.sourceReference,
    required this.sourceUrl,
  });

  final String name;
  final String category;
  final String description;
  final String location;
  final int travelMinutes;
  final int visitMinutes;
  final double distanceKm;
  final double estimatedCostLkr;
  final double estimatedCostUsd;
  final List<TransportOption> transportOptions;
  final double? latitude;
  final double? longitude;
  final String dataSource;
  final String? sourceReference;
  final String? sourceUrl;

  factory AlternativePlace.fromJson(Map<String, dynamic> json) => AlternativePlace(
        name: json['name'] as String? ?? 'Alternative place',
        category: json['category'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
        location: json['location'] as String? ?? '',
        travelMinutes: (json['travelMinutes'] as num?)?.toInt() ?? 0,
        visitMinutes: (json['visitMinutes'] as num?)?.toInt() ?? 120,
        distanceKm: _number(json['distanceKm']),
        estimatedCostLkr: _number(json['estimatedCostLkr']),
        estimatedCostUsd: _number(json['estimatedCostUsd']),
        transportOptions: (json['transportOptions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TransportOption.fromJson)
            .toList(growable: false),
        latitude: _nullableNumber(json['latitude']),
        longitude: _nullableNumber(json['longitude']),
        dataSource: json['dataSource'] as String? ?? 'UNKNOWN',
        sourceReference: json['sourceReference'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
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
    required this.visitMinutes,
    required this.distanceKm,
    required this.estimatedCostLkr,
    required this.estimatedCostUsd,
    required this.alternatives,
    required this.transportOptions,
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
  final int visitMinutes;
  final double distanceKm;
  final double estimatedCostLkr;
  final double estimatedCostUsd;
  final List<AlternativePlace> alternatives;
  final List<TransportOption> transportOptions;
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
        visitMinutes: (json['visitMinutes'] as num?)?.toInt() ?? 120,
        distanceKm: _number(json['distanceKm']),
        estimatedCostLkr: _number(json['estimatedCostLkr']),
        estimatedCostUsd: _number(json['estimatedCostUsd']),
        alternatives: (json['alternatives'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AlternativePlace.fromJson)
            .toList(growable: false),
        transportOptions: (json['transportOptions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TransportOption.fromJson)
            .toList(growable: false),
        latitude: _nullableNumber(json['latitude']),
        longitude: _nullableNumber(json['longitude']),
        dataSource: json['dataSource'] as String? ?? 'UNKNOWN',
        sourceReference: json['sourceReference'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
      );

  ItineraryItem usingAlternative(AlternativePlace alternative) => ItineraryItem(
        startTime: startTime,
        endTime: _addMinutes(startTime, alternative.visitMinutes),
        name: alternative.name,
        category: alternative.category,
        description: alternative.description,
        location: alternative.location,
        travelMinutes: alternative.travelMinutes,
        visitMinutes: alternative.visitMinutes,
        distanceKm: alternative.distanceKm,
        estimatedCostLkr: alternative.estimatedCostLkr,
        estimatedCostUsd: alternative.estimatedCostUsd,
        alternatives: [
          AlternativePlace(
            name: name,
            category: category,
            description: description,
            location: location,
            travelMinutes: travelMinutes,
            visitMinutes: visitMinutes,
            distanceKm: distanceKm,
            estimatedCostLkr: estimatedCostLkr,
            estimatedCostUsd: estimatedCostUsd,
            transportOptions: transportOptions,
            latitude: latitude,
            longitude: longitude,
            dataSource: dataSource,
            sourceReference: sourceReference,
            sourceUrl: sourceUrl,
          ),
          ...alternatives.where((value) => value.name != alternative.name),
        ],
        transportOptions: alternative.transportOptions,
        latitude: alternative.latitude,
        longitude: alternative.longitude,
        dataSource: alternative.dataSource,
        sourceReference: alternative.sourceReference,
        sourceUrl: alternative.sourceUrl,
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
    final itemsJson = json['items'] as List<dynamic>? ?? json['places'] as List<dynamic>? ?? const [];
    return ItineraryDay(
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? (json['day'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      theme: json['theme'] as String? ?? '',
      estimatedCostLkr: _number(json['estimatedCostLkr']),
      estimatedCostUsd: _number(json['estimatedCostUsd']),
      items: itemsJson.whereType<Map<String, dynamic>>().map(ItineraryItem.fromJson).toList(),
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

  ItineraryDay replacingItem(int index, AlternativePlace alternative) => ItineraryDay(
        dayNumber: dayNumber,
        date: date,
        theme: theme,
        estimatedCostLkr: estimatedCostLkr,
        estimatedCostUsd: estimatedCostUsd,
        items: [
          for (var i = 0; i < items.length; i++)
            if (i == index) items[i].usingAlternative(alternative) else items[i],
        ],
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
      providerNote: json['providerNote'] as String? ?? 'Saved itinerary using the development place catalogue.',
      destinationLatitude: _nullableNumber(json['destinationLatitude']),
      destinationLongitude: _nullableNumber(json['destinationLongitude']),
      costSummary: CostSummary.fromJson(json['costSummary'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      days: daysJson.whereType<Map<String, dynamic>>().map(ItineraryDay.fromJson).toList(),
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

  Itinerary withAlternative({
    required int dayIndex,
    required int itemIndex,
    required AlternativePlace alternative,
  }) => Itinerary(
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
            if (i == dayIndex) days[i].replacingItem(itemIndex, alternative) else days[i],
        ],
      );
}

double _number(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _nullableNumber(Object? value) => (value as num?)?.toDouble();

String _addMinutes(String hhmm, int minutes) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final total = (hour * 60 + minute + minutes) % (24 * 60);
  final h = (total ~/ 60).toString().padLeft(2, '0');
  final m = (total % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
