import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/storage/secure_storage_service.dart';

class TravellerProfile {
  const TravellerProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  final int id;
  final String username;
  final String email;
  final String role;

  factory TravellerProfile.fromJson(Map<String, dynamic> json) {
    return TravellerProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? 'traveller',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'TRAVELLER',
    );
  }
}

class ProfileException implements Exception {
  const ProfileException(this.message);
  final String message;
}

class ProfileRepository {
  ProfileRepository(this._apiService, this._secureStorage);

  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  TravellerProfile? _lastKnownProfile;

  Future<TravellerProfile> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      final data = response.data;
      if (data is Map) {
        final profile = TravellerProfile.fromJson(
          Map<String, dynamic>.from(data),
        );
        _lastKnownProfile = profile;
        return profile;
      }
      throw const ProfileException('Profile data was not returned.');
    } on DioException catch (error) {
      // Keep the Profile screen useful even if the dedicated profile request
      // temporarily fails. Login JWTs already contain the authenticated user id,
      // email (subject) and role, so these can safely populate the account card.
      final fallback = _lastKnownProfile ?? await _profileFromStoredToken();
      if (fallback != null) {
        return fallback;
      }
      throw ProfileException(_message(error));
    }
  }

  Future<TravellerProfile> updateUsername(String username) async {
    try {
      final response = await _apiService.updateUsername(username);
      final data = response.data;
      if (data is Map) {
        final profile = TravellerProfile.fromJson(
          Map<String, dynamic>.from(data),
        );
        _lastKnownProfile = profile;
        return profile;
      }
      throw const ProfileException('Profile update was not returned.');
    } on DioException catch (error) {
      throw ProfileException(_message(error));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on DioException catch (error) {
      throw ProfileException(_message(error));
    }
  }

  Future<TravellerProfile?> _profileFromStoredToken() async {
    final token = await _secureStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadText = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadText);
      if (payload is! Map) return null;

      final json = Map<String, dynamic>.from(payload);
      final email = json['sub']?.toString().trim() ?? '';
      if (email.isEmpty) return null;

      final userIdValue = json['userId'];
      final userId = userIdValue is num
          ? userIdValue.toInt()
          : int.tryParse(userIdValue?.toString() ?? '') ?? 0;
      final role = json['role']?.toString() ?? 'TRAVELLER';
      final at = email.indexOf('@');
      final username = at > 0 ? email.substring(0, at) : 'traveller';

      final profile = TravellerProfile(
        id: userId,
        username: username,
        email: email,
        role: role,
      );
      _lastKnownProfile = profile;
      return profile;
    } catch (_) {
      return null;
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (error.response?.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'Your account is not allowed to access this profile.';
      default:
        return 'Could not load account details. Please try again.';
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

final travellerProfileProvider = FutureProvider.autoDispose<TravellerProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});
