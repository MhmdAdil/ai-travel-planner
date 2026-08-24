import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../trip_preference/presentation/trip_preference_screen.dart';
import '../application/itinerary_controller.dart';
import '../application/itinerary_state.dart';
import '../data/models/itinerary.dart';

final _lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
final _usd = NumberFormat.currency(symbol: 'USD ', decimalDigits: 2);

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryControllerProvider);

    if (state.itinerary != null) return const _ItineraryResultView();
    if (state.status == ItineraryStatus.error) {
      return _ItineraryErrorView(
        message: state.errorMessage ?? 'Something went wrong. Please try again.',
        onRetry: () => ref.read(itineraryControllerProvider.notifier).regenerate(),
        onStartAgain: () => ref.read(itineraryControllerProvider.notifier).reset(),
      );
    }
    return const TripPreferenceScreen();
  }
}

class _ItineraryErrorView extends StatelessWidget {
  const _ItineraryErrorView({
    required this.message,
    required this.onRetry,
    required this.onStartAgain,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onStartAgain;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your Itinerary')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.teal),
                  const SizedBox(height: 16),
                  Text(
                    'We couldn\'t generate your itinerary',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  TextButton(onPressed: onStartAgain, child: const Text('Edit trip details')),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ItineraryResultView extends ConsumerWidget {
  const _ItineraryResultView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryControllerProvider);
    final itinerary = state.itinerary!;

    return Scaffold(
      appBar: AppBar(
        title: Text(itinerary.title),
        actions: [
          IconButton(
            tooltip: 'New plan',
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: state.isLoading
                ? null
                : () => ref.read(itineraryControllerProvider.notifier).reset(),
          ),
          IconButton(
            tooltip: 'Generate another version',
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(itineraryControllerProvider.notifier).regenerate(),
          ),
        ],
        bottom: state.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: itinerary.days.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return _PlanHeader(itinerary: itinerary);
            if (index == 1) return _CostSummaryCard(summary: itinerary.costSummary);
            final dayIndex = index - 2;
            return _DaySection(dayIndex: dayIndex, day: itinerary.days[dayIndex]);
          },
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${itinerary.days.length}-day plan for ${itinerary.destinationRegion}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    itinerary.providerNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _CostSummaryCard extends StatelessWidget {
  const _CostSummaryCard({required this.summary});

  final CostSummary summary;

  @override
  Widget build(BuildContext context) {
    final statusColor = summary.withinBudget ? Colors.green.shade700 : Colors.orange.shade800;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: AppColors.teal.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.teal),
                const SizedBox(width: 8),
                Text('Estimated trip cost', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            _CostRow(label: 'Accommodation', value: _lkr.format(summary.accommodationLkr)),
            _CostRow(label: 'Food', value: _lkr.format(summary.foodLkr)),
            _CostRow(label: 'Transport', value: _lkr.format(summary.transportLkr)),
            _CostRow(label: 'Activities', value: _lkr.format(summary.activitiesLkr)),
            const Divider(height: 20),
            _CostRow(label: 'Total', value: _lkr.format(summary.totalLkr), emphasized: true),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '≈ ${_usd.format(summary.totalUsd)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              summary.withinBudget
                  ? 'Within budget by ${_lkr.format(summary.budgetDifferenceLkr)}'
                  : 'Over budget by ${_lkr.format(summary.budgetDifferenceLkr)}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.rateNote} 1 USD ≈ ${summary.lkrPerUsd.toStringAsFixed(2)} LKR.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: emphasized ? FontWeight.bold : null)),
            Text(value, style: TextStyle(fontWeight: emphasized ? FontWeight.bold : null)),
          ],
        ),
      );
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.dayIndex, required this.day});

  final int dayIndex;
  final ItineraryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = day.date == null ? '' : DateFormat('EEE, d MMM').format(day.date!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                child: Text('${day.dayNumber}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${day.dayNumber} • $date', style: Theme.of(context).textTheme.titleLarge),
                    Text(day.theme, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(_lkr.format(day.estimatedCostLkr), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          if (day.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No activities remain for this day.'),
            )
          else
            ...List.generate(day.items.length, (itemIndex) {
              final item = day.items[itemIndex];
              return _ItineraryItemCard(
                item: item,
                onShowMap: item.hasCoordinates
                    ? () => _showPlaceMap(context, item)
                    : null,
                onRemove: () {
                  ref
                      .read(itineraryControllerProvider.notifier)
                      .removeItem(dayIndex: dayIndex, itemIndex: itemIndex);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from this view. Saved editing is added next.'),
                    ),
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}

class _ItineraryItemCard extends StatelessWidget {
  const _ItineraryItemCard({
    required this.item,
    required this.onRemove,
    required this.onShowMap,
  });

  final ItineraryItem item;
  final VoidCallback onRemove;
  final VoidCallback? onShowMap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_shortTime(item.startTime)}\n${_shortTime(item.endTime)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(item.category, style: const TextStyle(color: AppColors.teal)),
                        const SizedBox(height: 3),
                        Text(
                          item.dataSource == 'OPENSTREETMAP'
                              ? 'Live place • OpenStreetMap'
                              : item.dataSource == 'SYSTEM'
                                  ? 'Schedule information'
                                  : 'Verified fallback place',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onShowMap != null)
                    IconButton(
                      tooltip: 'Show on map',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.map_outlined, color: AppColors.teal),
                      onPressed: onShowMap,
                    ),
                  IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.description),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _Fact(icon: Icons.route, text: '${item.distanceKm.toStringAsFixed(1)} km'),
                  _Fact(icon: Icons.directions_car, text: '${item.travelMinutes} min travel'),
                  _Fact(
                    icon: Icons.payments_outlined,
                    text: '${_lkr.format(item.estimatedCostLkr)} (≈ ${_usd.format(item.estimatedCostUsd)})',
                  ),
                ],
              ),
              if (item.alternatives.isNotEmpty) ...[
                const Divider(height: 20),
                Text('Alternatives', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.alternatives
                      .map((alternative) => Chip(
                            avatar: const Icon(Icons.swap_horiz, size: 16),
                            label: Text(alternative),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

String _shortTime(String value) => value.length >= 5 ? value.substring(0, 5) : value;

void _showPlaceMap(BuildContext context, ItineraryItem item) {
  final point = LatLng(item.latitude!, item.longitude!);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 3),
                  Text(item.location, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 14.5),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ai_travel_planner_frontend',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.orange,
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
