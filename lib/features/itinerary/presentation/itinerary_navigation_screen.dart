import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../discover/data/discover_repository.dart';
import '../../discover/data/models/map_route.dart';

class ItineraryNavigationScreen extends ConsumerStatefulWidget {
  const ItineraryNavigationScreen({
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    super.key,
  });

  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;

  @override
  ConsumerState<ItineraryNavigationScreen> createState() => _ItineraryNavigationScreenState();
}

class _ItineraryNavigationScreenState extends ConsumerState<ItineraryNavigationScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  Position? _position;
  MapRoute? _route;
  bool _loading = true;
  String? _error;
  LatLng? _lastRouteOrigin;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for navigation.');
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      await _loadRoute(position);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((position) async {
        if (!mounted) return;
        setState(() => _position = position);
        final previous = _lastRouteOrigin;
        final moved = previous == null
            ? 9999.0
            : Geolocator.distanceBetween(
                previous.latitude,
                previous.longitude,
                position.latitude,
                position.longitude,
              );
        if (moved >= 75) await _loadRoute(position, quiet: true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadRoute(Position position, {bool quiet = false}) async {
    if (!quiet && mounted) setState(() => _loading = true);
    try {
      final route = await ref.read(discoverRepositoryProvider).fetchDirections(
            startLat: position.latitude,
            startLng: position.longitude,
            endLat: widget.destinationLatitude,
            endLng: widget.destinationLongitude,
          );
      if (!mounted) return;
      setState(() {
        _route = route;
        _lastRouteOrigin = LatLng(position.latitude, position.longitude);
        _loading = false;
        _error = null;
      });
      if (route.points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(route.points);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(44)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not calculate the road route. Check backend/internet and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _position == null ? null : LatLng(_position!.latitude, _position!.longitude);
    final destination = LatLng(widget.destinationLatitude, widget.destinationLongitude);
    final center = current ?? destination;

    return Scaffold(
      appBar: AppBar(title: Text('Navigate to ${widget.destinationName}')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ai_travel_planner_frontend',
              ),
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points,
                      strokeWidth: 5,
                      color: AppColors.teal,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (current != null)
                    Marker(
                      point: current,
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                          ),
                        ),
                      ),
                    ),
                  Marker(
                    point: destination,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on, size: 46, color: AppColors.orange),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _loading
                    ? const Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Calculating route…'),
                        ],
                      )
                    : _error != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              TextButton(
                                onPressed: _position == null ? _start : () => _loadRoute(_position!),
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.navigation, color: AppColors.teal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_route!.distanceKm.toStringAsFixed(1)} km • about ${_route!.durationMinutes} min\nLive location updates the route as you move.',
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white70),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
