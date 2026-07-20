import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../trip_preference/presentation/trip_preference_screen.dart';
import '../application/itinerary_controller.dart';
import '../application/itinerary_state.dart';
import '../data/models/itinerary.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryControllerProvider);

    if (state.itinerary != null) {
      return const _ItineraryResultView();
    }

    if (state.status == ItineraryStatus.error) {
      return _ItineraryErrorView(
        message: state.errorMessage ?? 'Something went wrong. Please try again.',
        onRetry: () => ref.read(itineraryControllerProvider.notifier).regenerate(),
      );
    }

    return const TripPreferenceScreen();
  }
}

class _ItineraryErrorView extends StatelessWidget {
  const _ItineraryErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItineraryResultView extends ConsumerWidget {
  const _ItineraryResultView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryControllerProvider);
    final itinerary = state.itinerary!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Itinerary'),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
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
        child: itinerary.days.isEmpty
            ? const Center(child: Text('No itinerary days to show.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: itinerary.days.length,
                itemBuilder: (context, dayIndex) {
                  final day = itinerary.days[dayIndex];
                  return _DaySection(dayIndex: dayIndex, day: day);
                },
              ),
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.dayIndex, required this.day});

  final int dayIndex;
  final ItineraryDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Day ${day.dayNumber}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (day.places.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'No places left for this day.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          )
        else
          ...List.generate(day.places.length, (placeIndex) {
            final place = day.places[placeIndex];
            return _PlaceCard(
              place: place,
              onRemove: () => ref
                  .read(itineraryControllerProvider.notifier)
                  .removePlace(dayIndex: dayIndex, placeIndex: placeIndex),
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onRemove});

  final ItineraryPlace place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.teal.withValues(alpha: 0.1),
              child: const Icon(Icons.place_outlined, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(place.category, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(place.visitDuration, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
