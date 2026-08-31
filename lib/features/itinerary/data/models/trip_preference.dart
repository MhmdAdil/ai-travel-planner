class TripPreference {
  const TripPreference({
    required this.destinationRegion,
    required this.startLocation,
    required this.arrivalDateTime,
    required this.departureDateTime,
    required this.budgetLevel,
    required this.budgetLkr,
    required this.groupSize,
    required this.travelRegions,
    required this.interests,
    required this.activities,
    required this.accommodationType,
    required this.foodPreference,
    required this.transportMode,
    required this.pace,
    required this.returnToAirport,
    this.notes,
    this.latitude,
    this.longitude,
  });

  final String destinationRegion;
  final String startLocation;
  final DateTime arrivalDateTime;
  final DateTime departureDateTime;
  final String budgetLevel;
  final double budgetLkr;
  final int groupSize;
  final List<String> travelRegions;
  final List<String> interests;
  final List<String> activities;
  final String accommodationType;
  final String foodPreference;
  final String transportMode;
  final String pace;
  final bool returnToAirport;
  final String? notes;
  final double? latitude;
  final double? longitude;

  int get durationDays {
    final arrivalDate = DateTime(arrivalDateTime.year, arrivalDateTime.month, arrivalDateTime.day);
    final departureDate = DateTime(departureDateTime.year, departureDateTime.month, departureDateTime.day);
    return departureDate.difference(arrivalDate).inDays + 1;
  }

  Map<String, dynamic> toJson() => {
        'destinationRegion': destinationRegion,
        'startLocation': startLocation,
        'arrivalDateTime': arrivalDateTime.toIso8601String(),
        'departureDateTime': departureDateTime.toIso8601String(),
        'budgetLevel': budgetLevel,
        'budgetLkr': budgetLkr,
        'groupSize': groupSize,
        'travelRegions': travelRegions,
        'interests': interests,
        'activities': activities,
        'accommodationType': accommodationType,
        'foodPreference': foodPreference,
        'transportMode': transportMode,
        'pace': pace,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
        'returnToAirport': returnToAirport,
      };
}
