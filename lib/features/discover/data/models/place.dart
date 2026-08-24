class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.averageCostLkr,
    required this.averageCostUsd,
    required this.feeStatus,
    required this.feeDetails,
    required this.address,
    required this.openingHours,
    required this.website,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.dataSource,
    required this.sourceUrl,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double? averageCostLkr;
  final double? averageCostUsd;
  final String feeStatus;
  final String feeDetails;
  final String address;
  final String openingHours;
  final String website;
  final String phone;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String dataSource;
  final String? sourceUrl;

  bool get hasVerifiedFee {
    if (feeStatus == 'FREE') return true;
    if (feeStatus != 'PAID') return false;
    if (averageCostLkr != null || averageCostUsd != null) return true;

    final details = feeDetails.trim().toLowerCase();
    return details.isNotEmpty &&
        !details.contains('not available') &&
        !details.contains('unavailable') &&
        !details.contains('unknown');
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Unnamed place',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      averageCostLkr: _toNullableDouble(
        json['averageCostLkr'] ?? json['averageCost'] ?? json['average_cost'],
      ),
      averageCostUsd: _toNullableDouble(json['averageCostUsd']),
      feeStatus: json['feeStatus'] as String? ?? 'UNKNOWN',
      feeDetails: json['feeDetails'] as String? ?? 'Cost information is unavailable.',
      address: json['address'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? '',
      website: json['website'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
      distanceKm: _toDouble(json['distanceKm']),
      dataSource: json['dataSource'] as String? ?? 'UNKNOWN',
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
