class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.averageCost,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double averageCost;
  final double latitude;
  final double longitude;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Unnamed place',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      averageCost: _toDouble(json['averageCost'] ?? json['average_cost']),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
