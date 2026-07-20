class ApiConfig {
  ApiConfig._();

  // Android emulator loopback to the host machine's localhost.
  // Point this at the real backend host when one is available.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const String loginPath = '/api/auth/login';
  static const String registerPath = '/api/auth/register';
  static const String generateItineraryPath = '/api/itinerary/generate';
}
