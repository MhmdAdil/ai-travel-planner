import 'package:latlong2/latlong.dart';

import '../data/discover_activity_filters.dart';
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
    this.selectedActivityFilters = const {},
  });

  final LatLng center;
  final double radiusKm;
  final List<Place> places;
  final DiscoverStatus status;
  final String? errorMessage;
  final bool locationDenied;
  final bool usingDeviceLocation;
  final Set<String> selectedActivityFilters;

  bool get isLoading => status == DiscoverStatus.loading;
  bool get includesOpenDataFallback => places.any(
        (place) => place.dataSource == 'OPENSTREETMAP_VERIFIED_SNAPSHOT' ||
            place.dataSource == 'OPENSTREETMAP_OFFLINE' ||
            place.dataSource == 'CURATED_OPEN_DATA',
      );
  List<Place> get visiblePlaces => places
      .where((place) => place.distanceKm <= radiusKm)
      .where((place) => matchesDiscoverActivityFilters(place.category, selectedActivityFilters))
      .toList(growable: false);

  DiscoverState copyWith({
    LatLng? center,
    double? radiusKm,
    List<Place>? places,
    DiscoverStatus? status,
    String? errorMessage,
    bool? locationDenied,
    bool? usingDeviceLocation,
    Set<String>? selectedActivityFilters,
  }) {
    return DiscoverState(
      center: center ?? this.center,
      radiusKm: radiusKm ?? this.radiusKm,
      places: places ?? this.places,
      status: status ?? this.status,
      errorMessage: errorMessage,
      locationDenied: locationDenied ?? this.locationDenied,
      usingDeviceLocation: usingDeviceLocation ?? this.usingDeviceLocation,
      selectedActivityFilters: selectedActivityFilters ?? this.selectedActivityFilters,
    );
  }
}
