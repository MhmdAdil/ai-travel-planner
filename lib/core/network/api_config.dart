class ApiConfig {
  ApiConfig._();

  // Android emulator loopback to the host machine's localhost by default.
  // Override for a physical device or deployed server with:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String loginPath = '/api/auth/login';
  static const String registerPath = '/api/auth/register';
  static const String generateItineraryPath = '/api/itinerary/generate';
  static const String itinerariesPath = '/api/itinerary';
  static const String nearbyPlacesPath = '/api/places/nearby';
  static const String placeRoutePath = '/api/places/route';
  static const String costPredictionPath = '/api/cost/predict';
  static const String chatMessagePath = '/api/chat/message';
  static const String profilePath = '/api/profile';
  static const String profileUsernamePath = '/api/profile/username';
  static const String profilePasswordPath = '/api/profile/password';
}
