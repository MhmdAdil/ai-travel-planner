import '../data/models/itinerary.dart';
import '../data/models/trip_preference.dart';

enum ItineraryStatus { initial, loading, success, error }

class ItineraryState {
  const ItineraryState({
    this.status = ItineraryStatus.initial,
    this.itinerary,
    this.errorMessage,
    this.lastPreference,
  });

  final ItineraryStatus status;
  final Itinerary? itinerary;
  final String? errorMessage;
  final TripPreference? lastPreference;

  bool get isLoading => status == ItineraryStatus.loading;

  ItineraryState copyWith({
    ItineraryStatus? status,
    Itinerary? itinerary,
    String? errorMessage,
    TripPreference? lastPreference,
  }) {
    return ItineraryState(
      status: status ?? this.status,
      itinerary: itinerary ?? this.itinerary,
      errorMessage: errorMessage,
      lastPreference: lastPreference ?? this.lastPreference,
    );
  }
}
