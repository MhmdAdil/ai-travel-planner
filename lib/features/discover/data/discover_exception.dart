class DiscoverException implements Exception {
  const DiscoverException(this.message);

  final String message;

  @override
  String toString() => message;
}
