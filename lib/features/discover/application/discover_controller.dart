import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/discover_exception.dart';
import '../data/discover_repository.dart';
import 'discover_state.dart';

class DiscoverController extends Notifier<DiscoverState> {
  static const LatLng sriLankaCenter = LatLng(7.8731, 80.7718);
  static const _locationChangeThresholdMeters = 100.0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationSafetyPoll;
  bool _pollInProgress = false;
  int _requestGeneration = 0;

  @override
  DiscoverState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _locationSafetyPoll?.cancel();
    });
    Future.microtask(_initialize);
    return const DiscoverState(center: sriLankaCenter);
  }

  Future<void> _initialize() async {
    await _refreshLocationAndFetch();
    _startLocationMonitoring();
  }

  Future<void> _refreshLocationAndFetch() async {
    final location = await _resolveLocation();
    final centerChanged = _centerMoved(location.center);
    if (centerChanged) {
      _requestGeneration++;
    }
    state = state.copyWith(
      center: location.center,
      locationDenied: !location.granted,
      usingDeviceLocation: location.granted,
      places: centerChanged ? const [] : state.places,
    );
    await fetchPlaces();
  }

  Future<void> setRadius(double radiusKm) async {
    if (state.radiusKm == radiusKm) return;
    state = state.copyWith(radiusKm: radiusKm);
    // Keep one stable map centre while comparing radii. Refreshing GPS here can move the
    // centre slightly and makes a 10 km search incomparable with the preceding 5 km search.
    await fetchPlaces();
  }

  Future<void> retry() => _refreshLocationAndFetch();

  Future<void> applyActivityFilters(Set<String> filters) async {
    state = state.copyWith(selectedActivityFilters: Set.unmodifiable(filters));
    await fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    if (state.locationDenied) {
      state = state.copyWith(
        status: DiscoverStatus.loaded,
        errorMessage: null,
        places: const [],
      );
      return;
    }

    final requestGeneration = ++_requestGeneration;
    final requestCenter = state.center;
    final requestRadius = state.radiusKm;
    final requestFilters = Set<String>.from(state.selectedActivityFilters);
    state = state.copyWith(status: DiscoverStatus.loading, errorMessage: null);
    try {
      final places = await ref.read(discoverRepositoryProvider).fetchNearby(
            lat: requestCenter.latitude,
            lng: requestCenter.longitude,
            radiusKm: requestRadius,
            activityFilters: requestFilters,
          ).timeout(const Duration(seconds: 50));
      if (!_isCurrentRequest(requestGeneration, requestCenter, requestRadius, requestFilters)) {
        return;
      }
      state = state.copyWith(status: DiscoverStatus.loaded, places: places);
    } on DiscoverException catch (e) {
      if (requestGeneration != _requestGeneration) return;
      // Keep the last successful markers visible when a public OSM refresh fails.
      // A genuine GPS-centre change already clears places in _acceptPosition, so
      // this cannot display markers from a previous city.
      state = state.copyWith(status: DiscoverStatus.error, errorMessage: e.message);
    } on TimeoutException {
      if (requestGeneration != _requestGeneration) return;
      state = state.copyWith(
        status: DiscoverStatus.error,
        errorMessage: 'Nearby places took too long to load. Please try again.',
      );
    } catch (_) {
      if (requestGeneration != _requestGeneration) return;
      state = state.copyWith(
        status: DiscoverStatus.error,
        errorMessage: 'Something went wrong while loading nearby places. Please try again.',
      );
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

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        return const _LocationResult(sriLankaCenter, false);
      }
      return _LocationResult(LatLng(position.latitude, position.longitude), true);
    } catch (_) {
      return const _LocationResult(sriLankaCenter, false);
    }
  }

  void _startLocationMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(
      (position) => unawaited(_acceptPosition(position)),
      onError: (_) {},
    );

    // Some emulator images do not emit a stream event after "Set Location".
    // This lightweight safety poll makes simulated and real GPS changes reliable.
    _locationSafetyPoll?.cancel();
    _locationSafetyPoll = Timer.periodic(
      const Duration(seconds: 6),
      (_) => unawaited(_pollCurrentPosition()),
    );
  }

  Future<void> _pollCurrentPosition() async {
    if (_pollInProgress) return;
    _pollInProgress = true;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await _acceptPosition(position);
    } catch (_) {
      // The stream and the explicit Retry action remain available.
    } finally {
      _pollInProgress = false;
    }
  }

  Future<void> _acceptPosition(Position position) async {
    final nextCenter = LatLng(position.latitude, position.longitude);
    if (!_centerMoved(nextCenter)) return;

    // Immediately invalidate requests from the previous location so a late
    // Colombo response cannot replace Nuwara Eliya (or any other new centre).
    _requestGeneration++;
    state = state.copyWith(
      center: nextCenter,
      locationDenied: false,
      usingDeviceLocation: true,
      places: const [],
      status: DiscoverStatus.loading,
      errorMessage: null,
    );
    await fetchPlaces();
  }

  bool _centerMoved(LatLng nextCenter) {
    if (!state.usingDeviceLocation) return true;
    final distance = const Distance().as(
      LengthUnit.Meter,
      state.center,
      nextCenter,
    );
    return distance >= _locationChangeThresholdMeters;
  }

  bool _isCurrentRequest(
    int generation,
    LatLng center,
    double radius,
    Set<String> filters,
  ) {
    return generation == _requestGeneration &&
        state.center.latitude == center.latitude &&
        state.center.longitude == center.longitude &&
        state.radiusKm == radius &&
        state.selectedActivityFilters.length == filters.length &&
        state.selectedActivityFilters.containsAll(filters);
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
