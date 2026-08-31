class CostPredictionException implements Exception {
  const CostPredictionException(this.message);

  final String message;

  @override
  String toString() => message;
}
