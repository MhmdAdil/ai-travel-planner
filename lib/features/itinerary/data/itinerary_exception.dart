class ItineraryException implements Exception {
  const ItineraryException(this.message);

  final String message;

  @override
  String toString() => message;
}
