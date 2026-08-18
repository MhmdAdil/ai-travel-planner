import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/itinerary_exception.dart';
import '../data/itinerary_repository.dart';
import '../data/models/trip_preference.dart';
import 'itinerary_state.dart';

class ItineraryController extends Notifier<ItineraryState> {
  @override
  ItineraryState build() => const ItineraryState();

  Future<void> generate(TripPreference preference) async {
    state = state.copyWith(
      status: ItineraryStatus.loading,
      errorMessage: null,
      lastPreference: preference,
    );
    try {
      final itinerary = await ref.read(itineraryRepositoryProvider).generate(preference);
      state = state.copyWith(status: ItineraryStatus.success, itinerary: itinerary);
    } on ItineraryException catch (e) {
      state = state.copyWith(status: ItineraryStatus.error, errorMessage: e.message);
    }
  }

  Future<void> regenerate() async {
    final preference = state.lastPreference;
    if (preference == null) return;
    await generate(preference);
  }

  void removeItem({required int dayIndex, required int itemIndex}) {
    final itinerary = state.itinerary;
    if (itinerary == null) return;
    state = state.copyWith(
      itinerary: itinerary.withItemRemoved(dayIndex: dayIndex, itemIndex: itemIndex),
    );
  }

  void reset() {
    state = const ItineraryState();
  }
}

final itineraryControllerProvider = NotifierProvider<ItineraryController, ItineraryState>(
  ItineraryController.new,
);
