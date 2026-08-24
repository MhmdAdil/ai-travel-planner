import 'package:latlong2/latlong.dart';

class MapRoute {
  const MapRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  factory MapRoute.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = rawPoints is List
        ? rawPoints
            .whereType<Map<String, dynamic>>()
            .map(
              (point) => LatLng(
                (point['latitude'] as num).toDouble(),
                (point['longitude'] as num).toDouble(),
              ),
            )
            .toList(growable: false)
        : const <LatLng>[];
    return MapRoute(
      points: points,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
