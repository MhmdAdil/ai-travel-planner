class TripPreference {
  const TripPreference({
    required this.region,
    required this.budget,
    required this.durationDays,
    required this.interests,
  });

  final String region;
  final double budget;
  final int durationDays;
  final List<String> interests;

  Map<String, dynamic> toJson() => {
        'region': region,
        'budget': budget,
        'durationDays': durationDays,
        'interests': interests,
      };
}
