import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discover_controller.dart';
import '../application/discover_state.dart';
import '../data/discover_activity_filters.dart';
import '../data/discover_exception.dart';
import '../data/discover_repository.dart';
import '../data/models/map_route.dart';
import '../data/models/place.dart';

const _radiusOptions = [1.0, 5.0, 10.0];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = const [];
  String? _routeLabel;
  bool _isRouting = false;

  void _showPlaceDetails(Place place) {
    final canRoute = ref.read(discoverControllerProvider).usingDeviceLocation;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _PlaceDetailsSheet(
        place: place,
        onDirections: canRoute
            ? () {
                Navigator.of(sheetContext).pop();
                _loadDirections(place);
              }
            : null,
        onNavigate: () {
          Navigator.of(sheetContext).pop();
          _startNavigation(place);
        },
      ),
    );
  }

  Future<void> _startNavigation(Place place) async {
    final nativeNavigation = Uri.parse(
      'google.navigation:q=${place.latitude},${place.longitude}&mode=d',
    );
    final browserNavigation = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.latitude},${place.longitude}',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    try {
      if (await canLaunchUrl(nativeNavigation)) {
        await launchUrl(nativeNavigation, mode: LaunchMode.externalApplication);
        return;
      }
      final opened = await launchUrl(
        browserNavigation,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw const FormatException('Navigation app unavailable');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open turn-by-turn navigation.')),
        );
      }
    }
  }

  Future<void> _loadDirections(Place place) async {
    final start = ref.read(discoverControllerProvider).center;
    setState(() {
      _isRouting = true;
      _routePoints = const [];
      _routeLabel = null;
    });
    try {
      final MapRoute route = await ref.read(discoverRepositoryProvider).fetchDirections(
            startLat: start.latitude,
            startLng: start.longitude,
            endLat: place.latitude,
            endLng: place.longitude,
          );
      if (!mounted) return;
      setState(() {
        _routePoints = route.points;
        _routeLabel = '${route.distanceKm.toStringAsFixed(1)} km • '
            '${route.durationMinutes} min by road';
      });
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.points),
          padding: const EdgeInsets.fromLTRB(44, 64, 44, 100),
        ),
      );
    } on DiscoverException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isRouting = false);
    }
  }

  Future<void> _selectActivities(Set<String> currentSelection) async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ActivityFilterSheet(initialSelection: currentSelection),
    );
    if (selected != null) {
      await ref.read(discoverControllerProvider.notifier).applyActivityFilters(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(discoverControllerProvider);

    ref.listen<DiscoverState>(discoverControllerProvider, (previous, next) {
      final centerChanged = previous == null ||
          previous.center.latitude != next.center.latitude ||
          previous.center.longitude != next.center.longitude;
      final radiusChanged = previous == null || previous.radiusKm != next.radiusKm;
      if (next.usingDeviceLocation && (centerChanged || radiusChanged)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (centerChanged && _routePoints.isNotEmpty) {
            setState(() {
              _routePoints = const [];
              _routeLabel = null;
            });
          }
          _mapController.move(next.center, _zoomForRadius(next.radiusKm));
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverTitle)),
      body: SafeArea(
        child: Column(
          children: [
            _RadiusSelector(
              selectedRadiusKm: state.radiusKm,
              onSelected: (radius) => ref.read(discoverControllerProvider.notifier).setRadius(radius),
            ),
            _ActivityFilterBar(
              selectedFilters: state.selectedActivityFilters,
              visibleCount: state.visiblePlaces.length,
              onPressed: () => _selectActivities(state.selectedActivityFilters),
            ),
            if (state.locationDenied)
              _LocationDeniedBanner(
                onRetry: () => ref.read(discoverControllerProvider.notifier).retry(),
              ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: state.center,
                      initialZoom: state.usingDeviceLocation ? 13 : 7.3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ai_travel_planner_frontend',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: state.center,
                            radius: state.radiusKm * 1000,
                            useRadiusInMeter: true,
                            color: AppColors.teal.withValues(alpha: 0.08),
                            borderColor: AppColors.teal.withValues(alpha: 0.8),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: AppColors.teal,
                              strokeWidth: 5,
                              borderColor: Colors.white,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (state.usingDeviceLocation)
                            Marker(
                              point: state.center,
                              width: 30,
                              height: 30,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          for (final place in state.visiblePlaces)
                            Marker(
                              point: LatLng(place.latitude, place.longitude),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showPlaceDetails(place),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.orange,
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (state.isLoading)
                    const Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: _LoadingPill()),
                    ),
                  if (_isRouting)
                    const Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: _RouteLoadingPill()),
                    ),
                  if (_routeLabel != null && !_isRouting)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: _RouteSummaryPill(
                        label: _routeLabel!,
                        onClose: () => setState(() {
                          _routePoints = const [];
                          _routeLabel = null;
                          _mapController.move(state.center, _zoomForRadius(state.radiusKm));
                        }),
                      ),
                    ),
                  if (state.status == DiscoverStatus.loaded &&
                      !state.locationDenied &&
                      state.selectedActivityFilters.isNotEmpty &&
                      state.visiblePlaces.isEmpty)
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: _NoMatchingPlacesPill(radiusKm: state.radiusKm),
                    ),
                  if (state.status == DiscoverStatus.error)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _DiscoverErrorBanner(
                        message: state.errorMessage ?? 'Something went wrong. Please try again.',
                        onRetry: () => ref.read(discoverControllerProvider.notifier).retry(),
                      ),
                    ),
                  Positioned(
                    left: 6,
                    bottom: state.status == DiscoverStatus.error || _routeLabel != null ? 82 : 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: Colors.white.withValues(alpha: 0.82),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 1) return 14.2;
    if (radiusKm <= 5) return 11.9;
    return 10.8;
  }
}

class _ActivityFilterBar extends StatelessWidget {
  const _ActivityFilterBar({
    required this.selectedFilters,
    required this.visibleCount,
    required this.onPressed,
  });

  final Set<String> selectedFilters;
  final int visibleCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = selectedFilters.isEmpty
        ? 'Select activities to show places'
        : '${selectedFilters.join(', ')} ($visibleCount)';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.tune, size: 18),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _ActivityFilterSheet extends StatefulWidget {
  const _ActivityFilterSheet({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late final Set<String> _selected = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select nearby activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Select one or more types to show matching places. Clear all to return to the map-only view.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in discoverActivityFilters.keys)
                  FilterChip(
                    label: Text(filter),
                    selected: _selected.contains(filter),
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selected.add(filter) : _selected.remove(filter);
                      });
                    },
                    selectedColor: AppColors.orange.withValues(alpha: 0.25),
                    checkmarkColor: AppColors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Clear all'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop({..._selected}),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchingPlacesPill extends StatelessWidget {
  const _NoMatchingPlacesPill({required this.radiusKm});

  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          'No selected activities were found within ${radiusKm.toInt()} km. '
          'Choose another activity type or a larger radius.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({required this.selectedRadiusKm, required this.onSelected});

  final double selectedRadiusKm;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final radius in _radiusOptions) ...[
            ChoiceChip(
              label: Text('${radius.toInt()} km'),
              selected: selectedRadiusKm == radius,
              onSelected: (selected) {
                if (selected) onSelected(radius);
              },
              selectedColor: AppColors.orange,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: selectedRadiusKm == radius ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
          ),
          SizedBox(width: 8),
          Text('Finding nearby places…'),
        ],
      ),
    );
  }
}

class _RouteLoadingPill extends StatelessWidget {
  const _RouteLoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
          ),
          SizedBox(width: 8),
          Text('Finding the road route…'),
        ],
      ),
    );
  }
}

class _RouteSummaryPill extends StatelessWidget {
  const _RouteSummaryPill({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.directions_car_outlined, color: AppColors.teal),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Route shown from your current location'),
        trailing: IconButton(
          tooltip: 'Close directions',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location permission is required for nearby results. Enable it, then tap Retry.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DiscoverErrorBanner extends StatelessWidget {
  const _DiscoverErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PlaceDetailsSheet extends StatelessWidget {
  const _PlaceDetailsSheet({
    required this.place,
    required this.onDirections,
    required this.onNavigate,
  });

  final Place place;
  final VoidCallback? onDirections;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final isCuratedOpenData = place.dataSource == 'CURATED_OPEN_DATA';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(place.category, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: AppColors.teal),
                const SizedBox(width: 4),
                Text('${place.distanceKm.toStringAsFixed(1)} km from map centre'),
              ],
            ),
            if (place.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                place.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            if (place.address.isNotEmpty)
              _PlaceFact(icon: Icons.location_on_outlined, text: place.address),
            if (place.openingHours.isNotEmpty)
              _PlaceFact(icon: Icons.schedule, text: 'Hours: ${place.openingHours}'),
            if (place.phone.isNotEmpty)
              _PlaceFact(icon: Icons.phone_outlined, text: place.phone),
            if (place.website.isNotEmpty)
              _PlaceFact(icon: Icons.language, text: place.website),
            if (place.hasVerifiedFee)
              _PlaceFact(icon: Icons.payments_outlined, text: place.feeDetails),
            if (!place.hasVerifiedFee)
              const _PlaceFact(
                icon: Icons.payments_outlined,
                text: 'Price: not published by the source.',
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isCuratedOpenData
                    ? 'Source-linked place information. Verify access and safety conditions locally.'
                    : 'Community-listed OpenStreetMap place information. Verify access and safety conditions locally.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Start navigation'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions, size: 18),
                    label: Text(onDirections == null ? 'Enable GPS' : 'Get directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceFact extends StatelessWidget {
  const _PlaceFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
