import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService({ApiClient? apiClient, FlutterSecureStorage? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
  static const String _apiClientIdKey = 'api_client_id';
  static const String _resolvedClientUuidKey = 'resolved_client_uuid';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  /// Exchanges API Client ID and Client Secret for a short-lived JWT.
  Future<AuthResponse> fetchToken({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.authToken,
        data: {
          'clientId': clientId.trim(),
          'clientSecret': clientSecret.trim(),
        },
      );

      final AuthResponse auth = AuthResponse.fromJson(response.data);

      if (!auth.success) {
        throw Exception(auth.error ?? 'API authentication failed.');
      }

      final String? token = auth.token;

      if (token == null || token.isEmpty) {
        throw Exception('JWT token was not returned by the API.');
      }

      await _storage.write(key: _tokenKey, value: token);

      final String savedApiClientId = auth.clientId?.isNotEmpty == true
          ? auth.clientId!
          : clientId.trim();

      await _storage.write(key: _apiClientIdKey, value: savedApiClientId);

      debugPrint('[AuthService] API token saved successfully.');

      return auth;
    } catch (error) {
      debugPrint('[AuthService] Token exchange failed: $error');

      rethrow;
    }
  }

  /// Email/password login for tenant or mobile users.
  Future<AuthResponse> tenantLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.authLogin,
        data: {'email': email.trim(), 'password': password},
      );

      debugPrint('[LOGIN RAW RESPONSE] ${response.data}');

      final AuthResponse auth = AuthResponse.fromJson(response.data);

      if (!auth.success) {
        throw Exception(auth.error ?? 'Login failed.');
      }

      final String? token = auth.token;

      if (token == null || token.isEmpty) {
        throw Exception('JWT token was not returned by the API.');
      }

      await _storage.write(key: _tokenKey, value: token);

      if (auth.clientId != null && auth.clientId!.isNotEmpty) {
        await _storage.write(key: _apiClientIdKey, value: auth.clientId);
      }

      debugPrint('[AuthService] Tenant login successful.');

      return auth;
    } catch (error) {
      debugPrint('[AuthService] Tenant login failed: $error');

      rethrow;
    }
  }

  /// Sends OTP to the given phone number.
  Future<AuthResponse> sendOtp({required String phone}) async {
    try {
      final response = await _api.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phone.trim()},
      );
      final AuthResponse auth = AuthResponse.fromJson(response.data);
      if (!auth.success) {
        throw Exception(auth.error ?? 'Failed to send OTP');
      }
      return auth;
    } catch (error) {
      debugPrint('[AuthService] sendOtp failed: $error');
      rethrow;
    }
  }

  /// Verifies OTP and returns authentication token.
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone.trim(), 'otp': otp.trim()},
      );
      final AuthResponse auth = AuthResponse.fromJson(response.data);
      if (!auth.success) {
        throw Exception(auth.error ?? 'OTP verification failed');
      }
      return auth;
    } catch (error) {
      debugPrint('[AuthService] verifyOtp failed: $error');
      rethrow;
    }
  }

  Future<bool> hasValidToken() async {
    final String? token = await getSavedToken();

    return token != null && token.isNotEmpty;
  }

  Future<String?> getSavedToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> getSavedApiClientId() {
    return _storage.read(key: _apiClientIdKey);
  }

  Future<String?> getResolvedClientUuid() {
    return _storage.read(key: _resolvedClientUuidKey);
  }

  Future<void> saveResolvedClientUuid(String clientUuid) async {
    await _storage.write(key: _resolvedClientUuidKey, value: clientUuid);
  }

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _resolvedClientUuidKey),
      _storage.delete(key: _apiClientIdKey),
    ]);

    debugPrint('[AuthService] Authentication data cleared.');
  }
}
