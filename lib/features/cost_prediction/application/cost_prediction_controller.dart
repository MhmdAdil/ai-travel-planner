import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../itinerary/data/models/itinerary.dart';
import '../../itinerary/data/models/trip_preference.dart';
import '../data/cost_prediction_exception.dart';
import '../data/cost_prediction_input_builder.dart';
import '../data/cost_prediction_repository.dart';
import 'cost_prediction_state.dart';

class CostPredictionController extends Notifier<CostPredictionState> {
  @override
  CostPredictionState build() => const CostPredictionState();

  Future<void> predict({
    required TripPreference preference,
    required Itinerary itinerary,
    bool force = false,
  }) async {
    final request = CostPredictionInputBuilder.fromItinerary(
      preference: preference,
      itinerary: itinerary,
    );
    final fingerprint = request.fingerprint;

    if (!force &&
        (state.isLoading ||
            (state.status == CostPredictionStatus.success &&
                state.sourceFingerprint == fingerprint))) {
      return;
    }

    state = CostPredictionState(
      status: CostPredictionStatus.loading,
      sourceFingerprint: fingerprint,
    );

    try {
      final prediction =
          await ref.read(costPredictionRepositoryProvider).predict(request);
      state = CostPredictionState(
        status: CostPredictionStatus.success,
        prediction: prediction,
        sourceFingerprint: fingerprint,
      );
    } on CostPredictionException catch (e) {
      state = CostPredictionState(
        status: CostPredictionStatus.error,
        errorMessage: e.message,
        sourceFingerprint: fingerprint,
      );
    }
  }

  void reset() {
    state = const CostPredictionState();
  }
}

final costPredictionControllerProvider =
    NotifierProvider<CostPredictionController, CostPredictionState>(
  CostPredictionController.new,
);
