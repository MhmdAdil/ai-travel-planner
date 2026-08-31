import '../data/models/cost_prediction.dart';

enum CostPredictionStatus { initial, loading, success, error }

class CostPredictionState {
  const CostPredictionState({
    this.status = CostPredictionStatus.initial,
    this.prediction,
    this.errorMessage,
    this.sourceFingerprint,
  });

  final CostPredictionStatus status;
  final CostPrediction? prediction;
  final String? errorMessage;
  final String? sourceFingerprint;

  bool get isLoading => status == CostPredictionStatus.loading;
}
