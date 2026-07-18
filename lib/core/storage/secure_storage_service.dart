import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});
