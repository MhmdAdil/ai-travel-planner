import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discover_controller.dart';
import '../application/discover_state.dart';
import '../data/models/place.dart';

const _radiusOptions = [1.0, 5.0, 10.0];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final MapController _mapController = MapController();

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlaceDetailsSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(discoverControllerProvider);

    ref.listen<DiscoverState>(discoverControllerProvider, (previous, next) {
      final justResolvedDeviceLocation =
          next.usingDeviceLocation && previous?.usingDeviceLocation != true;
      if (justResolvedDeviceLocation) {
        _mapController.move(next.center, 13);
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
            if (state.locationDenied) const _LocationDeniedBanner(),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: state.center,
                      initialZoom: 7.3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ai_travel_planner_frontend',
                      ),
                      MarkerLayer(
                        markers: [
                          for (final place in state.places)
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
                ],
              ),
            ),
          ],
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

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner();

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
              'Location permission not granted. Showing places around Sri Lanka.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
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
  const _PlaceDetailsSheet({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
            if (place.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                place.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  'Avg. cost: \$${place.averageCost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Place details coming soon.')),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}
