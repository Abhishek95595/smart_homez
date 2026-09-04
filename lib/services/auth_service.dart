import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService({ApiClient? apiClient, FlutterSecureStorage? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String tenantApiJwtKey = 'tenant_api_jwt';
  static const String tenantApiJwtExpiresAtKey = 'tenant_api_jwt_expires_at';
  static const String platformUserJwtKey = 'platform_user_jwt';
  static const String clientApiJwtKey = 'client_api_jwt';
  static const String _apiClientIdKey = 'api_client_id';
  static const String _resolvedClientUuidKey = 'resolved_client_uuid';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  /// Fetches a production Tenant API token from the Firebase Cloud Functions token broker (BFF).
  Future<String?> fetchTenantApiTokenFromBff() async {
    return _api.getValidTenantApiToken();
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

      debugPrint(
        '[LOGIN] success=${response.data?['success']} '
        'clientId=${response.data?['clientId']} '
        'userType=${response.data?['userType']}',
      );

      final AuthResponse auth = AuthResponse.fromJson(response.data);

      if (!auth.success) {
        throw Exception(auth.error ?? 'Login failed.');
      }

      final String? token = auth.token;

      if (token == null || token.isEmpty) {
        throw Exception('JWT token was not returned by the API.');
      }

      await _storage.write(key: platformUserJwtKey, value: token);
      await _storage.write(key: clientApiJwtKey, value: token);
      await _storage.delete(key: 'jwt_token');

      if (auth.clientId != null && auth.clientId!.isNotEmpty) {
        await _storage.write(key: _apiClientIdKey, value: auth.clientId);
      }
      await _storage.write(key: 'login_email', value: email.trim());
      await _storage.write(key: 'login_password', value: password);

      debugPrint(
        '[AuthService] Tenant user login successful with mapped client token.',
      );

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

      if (auth.token != null && auth.token!.isNotEmpty) {
        await _storage.write(key: clientApiJwtKey, value: auth.token);
        await _storage.write(key: platformUserJwtKey, value: auth.token);
      }
      if (auth.clientId != null && auth.clientId!.isNotEmpty) {
        await _storage.write(key: _apiClientIdKey, value: auth.clientId);
      }

      return auth;
    } catch (error) {
      debugPrint('[AuthService] verifyOtp failed: $error');
      rethrow;
    }
  }

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  /// Calls the getTenantSession Firebase Callable Function.
  Future<Map<String, dynamic>> getTenantSession({String? fcmToken}) async {
    try {
      final callable = _functions.httpsCallable('getTenantSession');
      final result = await callable.call(<String, dynamic>{
        'fcmToken': fcmToken,
      });

      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true && data['client'] != null) {
        final String? clientId = data['client']['id'];
        if (clientId != null && clientId.isNotEmpty) {
          await _storage.write(key: _resolvedClientUuidKey, value: clientId);
        }
      }

      return data;
    } catch (error) {
      debugPrint('[AuthService] getTenantSession failed: $error');
      rethrow;
    }
  }

  /// Calls the registerTenantClient Firebase Callable Function.
  Future<Map<String, dynamic>> registerTenantClient({
    required String name,
    String? fcmToken,
  }) async {
    try {
      final callable = _functions.httpsCallable('registerTenantClient');
      final result = await callable.call(<String, dynamic>{
        'name': name.trim(),
        'fcmToken': fcmToken,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (error) {
      debugPrint('[AuthService] registerTenantClient failed: $error');
      rethrow;
    }
  }

  /// Calls the verifyTenantClient Firebase Callable Function.
  Future<Map<String, dynamic>> verifyTenantClient({
    required String code,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyTenantClient');
      final result = await callable.call(<String, dynamic>{
        'code': code.trim(),
      });

      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true) {
        final String? clientId = data['clientId'];
        if (clientId != null && clientId.isNotEmpty) {
          await _storage.write(key: _resolvedClientUuidKey, value: clientId);
        }
      }

      return data;
    } catch (error) {
      debugPrint('[AuthService] verifyTenantClient failed: $error');
      rethrow;
    }
  }

  /// Calls the resendTenantRegistrationOtp Firebase Callable Function.
  Future<Map<String, dynamic>> resendTenantRegistrationOtp() async {
    try {
      final callable = _functions.httpsCallable('resendTenantRegistrationOtp');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data);
    } catch (error) {
      debugPrint('[AuthService] resendTenantRegistrationOtp failed: $error');
      rethrow;
    }
  }

  Future<bool> hasValidToken() async {
    final String? token = await getSavedToken();

    return token != null && token.isNotEmpty;
  }

  Future<String?> getSavedToken() async {
    final String? userToken = await _storage.read(key: platformUserJwtKey);
    if (userToken != null && userToken.isNotEmpty) return userToken;
    return _storage.read(key: clientApiJwtKey);
  }

  Future<String?> getSavedApiClientId() {
    return _storage.read(key: _apiClientIdKey);
  }

  Future<String?> getSavedClientSecret() {
    return _storage.read(key: 'api_client_secret');
  }

  Future<String?> getSavedEmail() {
    return _storage.read(key: 'login_email');
  }

  Future<String?> getSavedPassword() {
    return _storage.read(key: 'login_password');
  }

  Future<String?> getUserId() {
    return _storage.read(key: 'user_id');
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<void> savePlatformUserJwt(String token) async {
    await _storage.write(key: platformUserJwtKey, value: token);
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> saveFirebaseIdToken(String token) async {
    await _storage.write(key: 'firebase_id_token', value: token);
  }

  Future<String?> getFirebaseIdToken() {
    return _storage.read(key: 'firebase_id_token');
  }

  Future<String?> getResolvedClientUuid() async {
    final String? stored = await _storage.read(key: _resolvedClientUuidKey);
    final bool needsMigration =
        stored == null ||
        stored.trim().isEmpty ||
        stored.trim() != ApiEndpoints.productionClientGuid;
    final String resolvedValue = ApiEndpoints.productionClientGuid;

    if (needsMigration) {
      await _storage.write(
        key: _resolvedClientUuidKey,
        value: ApiEndpoints.productionClientGuid,
      );
      await _storage.write(
        key: 'user_id',
        value: ApiEndpoints.productionClientGuid,
      );
    }

    debugPrint('[Client UUID] stored value = $stored');
    debugPrint('[Client UUID] resolved value = $resolvedValue');
    debugPrint('[Client UUID] migrated = ${needsMigration ? "true" : "false"}');

    return resolvedValue;
  }

  Future<void> saveResolvedClientUuid(String clientUuid) async {
    await _storage.write(key: _resolvedClientUuidKey, value: clientUuid);
  }

  Future<void> clearSession() => logout();

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: tenantApiJwtKey),
      _storage.delete(key: tenantApiJwtExpiresAtKey),
      _storage.delete(key: platformUserJwtKey),
      _storage.delete(key: clientApiJwtKey),
      _storage.delete(key: 'jwt_token'),
      _storage.delete(key: 'user_id'),
      _storage.delete(key: _resolvedClientUuidKey),
      _storage.delete(key: _apiClientIdKey),
      _storage.delete(key: 'api_client_secret'),
      _storage.delete(key: 'login_email'),
      _storage.delete(key: 'login_password'),
      _storage.delete(key: 'firebase_id_token'),
    ]);

    debugPrint('[AuthService] Authentication data cleared.');
  }
}
