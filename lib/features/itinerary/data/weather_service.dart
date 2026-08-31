import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PlaceWeather {
  const PlaceWeather({
    required this.summary,
    required this.minC,
    required this.maxC,
    required this.rainChance,
  });

  final String summary;
  final double minC;
  final double maxC;
  final int rainChance;
}

class WeatherService {
  WeatherService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.open-meteo.com/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static final Map<String, Future<PlaceWeather?>> _cache = {};

  static Future<PlaceWeather?> forPlace({
    required double latitude,
    required double longitude,
    required DateTime? date,
  }) {
    final target = date ?? DateTime.now();
    final day = DateFormat('yyyy-MM-dd').format(target);
    final key = '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)},$day';
    return _cache.putIfAbsent(
      key,
      () => _fetch(latitude: latitude, longitude: longitude, day: day),
    );
  }

  static Future<PlaceWeather?> _fetch({
    required double latitude,
    required double longitude,
    required String day,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
          'timezone': 'auto',
          'start_date': day,
          'end_date': day,
        },
      );
      final daily = response.data?['daily'];
      if (daily is! Map<String, dynamic>) return null;
      final codes = daily['weather_code'] as List<dynamic>?;
      final maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
      final minTemps = daily['temperature_2m_min'] as List<dynamic>?;
      final rain = daily['precipitation_probability_max'] as List<dynamic>?;
      if (codes == null || codes.isEmpty || maxTemps == null || maxTemps.isEmpty || minTemps == null || minTemps.isEmpty) {
        return null;
      }
      return PlaceWeather(
        summary: _description((codes.first as num).toInt()),
        minC: (minTemps.first as num).toDouble(),
        maxC: (maxTemps.first as num).toDouble(),
        rainChance: rain == null || rain.isEmpty ? 0 : (rain.first as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static String _description(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 95) return 'Thunderstorms';
    return 'Mixed weather';
  }
}
