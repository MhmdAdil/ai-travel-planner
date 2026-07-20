class ItineraryPlace {
  const ItineraryPlace({
    required this.name,
    required this.category,
    required this.visitDuration,
  });

  final String name;
  final String category;
  final String visitDuration;

  factory ItineraryPlace.fromJson(Map<String, dynamic> json) {
    return ItineraryPlace(
      name: json['name'] as String? ?? 'Unknown place',
      category: json['category'] as String? ?? 'General',
      visitDuration: (json['visitDuration'] ?? json['duration'])?.toString() ?? 'Unknown',
    );
  }
}

class ItineraryDay {
  ItineraryDay({required this.dayNumber, required List<ItineraryPlace> places})
      : places = List.unmodifiable(places);

  final int dayNumber;
  final List<ItineraryPlace> places;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final placesJson = json['places'] as List<dynamic>? ?? const [];
    return ItineraryDay(
      dayNumber: json['day'] as int? ?? json['dayNumber'] as int? ?? 0,
      places: placesJson
          .whereType<Map<String, dynamic>>()
          .map(ItineraryPlace.fromJson)
          .toList(),
    );
  }

  ItineraryDay withoutPlaceAt(int index) {
    return ItineraryDay(
      dayNumber: dayNumber,
      places: [for (var i = 0; i < places.length; i++) if (i != index) places[i]],
    );
  }
}

class Itinerary {
  Itinerary({required List<ItineraryDay> days}) : days = List.unmodifiable(days);

  final List<ItineraryDay> days;

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? const [];
    return Itinerary(
      days: daysJson.whereType<Map<String, dynamic>>().map(ItineraryDay.fromJson).toList(),
    );
  }

  Itinerary withPlaceRemoved({required int dayIndex, required int placeIndex}) {
    return Itinerary(
      days: [
        for (var i = 0; i < days.length; i++)
          if (i == dayIndex) days[i].withoutPlaceAt(placeIndex) else days[i],
      ],
    );
  }
}
