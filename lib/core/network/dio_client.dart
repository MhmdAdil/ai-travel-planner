import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';
import 'api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      // The backend fails over to its source-linked nationwide OSM index.
      receiveTimeout: const Duration(seconds: 50),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Do not attach a stale JWT to public read-only endpoints. Spring's resource-server
        // filter may reject an invalid bearer token even when the endpoint itself is public.
        if (requiresAuthentication(options.path)) {
          final token = await ref.read(secureStorageServiceProvider).readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

bool requiresAuthentication(String path) {
  return path != ApiConfig.loginPath &&
      path != ApiConfig.registerPath &&
      path != ApiConfig.nearbyPlacesPath &&
      path != ApiConfig.placeRoutePath;
}
