import 'package:latlong2/latlong.dart';

import '../data/models/place.dart';

enum DiscoverStatus { loading, loaded, error }

class DiscoverState {
  const DiscoverState({
    required this.center,
    this.radiusKm = 5,
    this.places = const [],
    this.status = DiscoverStatus.loading,
    this.errorMessage,
    this.locationDenied = false,
    this.usingDeviceLocation = false,
  });

  final LatLng center;
  final double radiusKm;
  final List<Place> places;
  final DiscoverStatus status;
  final String? errorMessage;
  final bool locationDenied;
  final bool usingDeviceLocation;

  bool get isLoading => status == DiscoverStatus.loading;

  DiscoverState copyWith({
    LatLng? center,
    double? radiusKm,
    List<Place>? places,
    DiscoverStatus? status,
    String? errorMessage,
    bool? locationDenied,
    bool? usingDeviceLocation,
  }) {
    return DiscoverState(
      center: center ?? this.center,
      radiusKm: radiusKm ?? this.radiusKm,
      places: places ?? this.places,
      status: status ?? this.status,
      errorMessage: errorMessage,
      locationDenied: locationDenied ?? this.locationDenied,
      usingDeviceLocation: usingDeviceLocation ?? this.usingDeviceLocation,
    );
  }
}
