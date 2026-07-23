import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/discover_exception.dart';
import '../data/discover_repository.dart';
import 'discover_state.dart';

class DiscoverController extends Notifier<DiscoverState> {
  static const LatLng sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  DiscoverState build() {
    Future.microtask(_initialize);
    return const DiscoverState(center: sriLankaCenter);
  }

  Future<void> _initialize() async {
    final location = await _resolveLocation();
    state = state.copyWith(
      center: location.center,
      locationDenied: !location.granted,
      usingDeviceLocation: location.granted,
    );
    await fetchPlaces();
  }

  Future<void> setRadius(double radiusKm) async {
    if (state.radiusKm == radiusKm) return;
    state = state.copyWith(radiusKm: radiusKm);
    await fetchPlaces();
  }

  Future<void> retry() => fetchPlaces();

  Future<void> fetchPlaces() async {
    state = state.copyWith(status: DiscoverStatus.loading, errorMessage: null);
    try {
      final places = await ref.read(discoverRepositoryProvider).fetchNearby(
            lat: state.center.latitude,
            lng: state.center.longitude,
            radiusKm: state.radiusKm,
          );
      state = state.copyWith(status: DiscoverStatus.loaded, places: places);
    } on DiscoverException catch (e) {
      state = state.copyWith(status: DiscoverStatus.error, errorMessage: e.message, places: const []);
    }
  }

  Future<_LocationResult> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const _LocationResult(sriLankaCenter, false);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return const _LocationResult(sriLankaCenter, false);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return _LocationResult(LatLng(position.latitude, position.longitude), true);
    } catch (_) {
      return const _LocationResult(sriLankaCenter, false);
    }
  }
}

class _LocationResult {
  const _LocationResult(this.center, this.granted);

  final LatLng center;
  final bool granted;
}

final discoverControllerProvider = NotifierProvider<DiscoverController, DiscoverState>(
  DiscoverController.new,
);
