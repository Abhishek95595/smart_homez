import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  static const String tenantApiJwtKey = 'tenant_api_jwt';
  static const String tenantApiJwtExpiresAtKey = 'tenant_api_jwt_expires_at';

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          try {
            String path = options.path;

            // Hard safety guard: Normalize any /api/v1/clients/{clientId} path to productionClientGuid
            final clientPathRegex = RegExp(
              r'^/api/v1/clients/([0-9a-fA-F-]+)(/.*)?$',
            );
            final match = clientPathRegex.firstMatch(path);
            if (match != null) {
              final extractedId = match.group(1);
              final rest = match.group(2) ?? '';
              if (extractedId != 'resolve' &&
                  extractedId != 'createClient' &&
                  extractedId != ApiEndpoints.productionClientGuid) {
                path =
                    '/api/v1/clients/${ApiEndpoints.productionClientGuid}$rest';
                options.path = path;
              }
            }

            // Obtain the authoritative valid Tenant API JWT
            final String? token = await getValidTenantApiToken();

            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${token.trim()}';
              debugPrint('[API] Tenant JWT source = tenant_api_jwt');
              debugPrint('[API] Tenant = ${ApiEndpoints.productionTenantId}');
              debugPrint(
                '[API] AuraBrain ClientId = ${ApiEndpoints.expectedTenantClientId}',
              );
            } else {
              options.headers.remove('Authorization');
            }

            debugPrint('[API Request] ${options.method} $path');
            return handler.next(options);
          } catch (error) {
            debugPrint('[API Auth] Request interceptor error: $error');
            return handler.next(options);
          }
        },

        onResponse:
            (Response<dynamic> response, ResponseInterceptorHandler handler) {
              debugPrint(
                '[API Response] '
                '${response.statusCode} '
                '${response.requestOptions.path}',
              );
              return handler.next(response);
            },

        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final int? statusCode = error.response?.statusCode;
          final String path = error.requestOptions.path;
          final bool isRetry = error.requestOptions.extra['isRetry'] == true;

          debugPrint(
            '[API Error] '
            '$statusCode '
            '$path',
          );

          if (statusCode == 401 && !isRetry) {
            if (path == ApiEndpoints.authLogin) {
              return handler.next(error);
            }

            try {
              debugPrint('[API] 401 → refreshing Tenant API token');
              final String? refreshedToken = await _refreshToken();
              if (refreshedToken != null && refreshedToken.isNotEmpty) {
                final RequestOptions options = error.requestOptions;
                options.extra['isRetry'] = true;
                options.headers['Authorization'] = 'Bearer $refreshedToken';
                debugPrint('[API] retry = true');
                final Dio retryDio = Dio(
                  BaseOptions(
                    baseUrl: ApiEndpoints.baseUrl,
                    headers: options.headers,
                  ),
                );
                final Response<dynamic> retryResponse = await retryDio
                    .fetch<dynamic>(options);
                return handler.resolve(retryResponse);
              }
            } catch (retryErr) {
              debugPrint('[API Auth] Retry execution notice: $retryErr');
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?>? _refreshFuture;

  /// Retrieves a validated production Tenant API JWT.
  /// If expired, invalid, or missing, requests a fresh token from Firebase Cloud Function.
  Future<String?> getValidTenantApiToken() async {
    // 1. Check authoritative tenant_api_jwt key
    String? token = await _storage.read(key: tenantApiJwtKey);

    // Legacy migration check if tenant_api_jwt is not yet set
    if (token == null || token.isEmpty) {
      final String? legacyClient = await _storage.read(key: 'client_api_jwt');
      if (isJwtValid(legacyClient)) {
        token = legacyClient;
        await _storage.write(key: tenantApiJwtKey, value: token);
      }
      await _storage.delete(key: 'client_api_jwt');
    }

    if (token != null && isJwtValid(token)) {
      return token;
    }

    // 2. Token is missing or expired -> request fresh token through Firebase BFF
    return _refreshToken();
  }

  Future<String?> _refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _doRefreshToken();
    try {
      final token = await _refreshFuture;
      return token;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _doRefreshToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint(
          '[API Auth] No Firebase user authenticated, cannot request Tenant API token.',
        );
        return null;
      }

      debugPrint('[Auth] Requesting Tenant API token from Cloud Function');
      final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
      final callable = functions.httpsCallable('getTenantApiToken');
      final result = await callable.call<dynamic>();

      if (result.data is Map) {
        final Map data = result.data as Map;
        final String? token = data['token']?.toString();
        final String? expiresAt = data['expiresAt']?.toString();

        if (token != null && isJwtValid(token)) {
          debugPrint('[Auth] Tenant API token received');
          if (expiresAt != null) {
            debugPrint('[Auth] Tenant token expiresAt = $expiresAt');
            await _storage.write(
              key: tenantApiJwtExpiresAtKey,
              value: expiresAt,
            );
          }
          await _storage.write(key: tenantApiJwtKey, value: token);
          await _storage.delete(key: 'client_api_jwt');
          await _storage.delete(key: 'platform_user_jwt');
          await _storage.delete(key: 'jwt_token');
          return token;
        }
      }
    } catch (e) {
      debugPrint('[API Auth] Error fetching Tenant token from BFF: $e');
    }
    return null;
  }

  static Map<String, dynamic>? parseJwtPayload(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final List<String> parts = token.trim().split('.');
    if (parts.length != 3) return null;
    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payloadString = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool isJwtValid(String? token) {
    if (token == null || token.trim().isEmpty) return false;
    final Map<String, dynamic>? decoded = parseJwtPayload(token);
    if (decoded == null) return false;

    // 1. Reject Firebase ID tokens & verify AuraBrain issuer
    final dynamic iss = decoded['iss'];
    if (iss == null ||
        iss.toString().contains('securetoken.google.com') ||
        iss.toString() != ApiEndpoints.expectedJwtIssuer) {
      return false;
    }

    // 2. Verify Audience
    final dynamic aud = decoded['aud'];
    if (aud == null || aud.toString() != ApiEndpoints.expectedJwtAudience) {
      return false;
    }

    // 3. Verify Production Tenant ID
    final dynamic tenantId = decoded['TenantId'] ?? decoded['tenantId'];
    if (tenantId == null ||
        tenantId.toString() != ApiEndpoints.productionTenantId) {
      return false;
    }

    // 4. Verify Expected Tenant Client ID
    final dynamic clientId = decoded['ClientId'] ?? decoded['clientId'];
    if (clientId == null ||
        clientId.toString() != ApiEndpoints.expectedTenantClientId) {
      return false;
    }

    // 5. Verify Permission Level
    final dynamic permission =
        decoded['PermissionLevel'] ?? decoded['permissionLevel'];
    if (permission == null ||
        permission.toString() != ApiEndpoints.expectedJwtPermission) {
      return false;
    }

    // 6. Verify Expiration (with 60-second safety margin)
    if (decoded['exp'] == null) return false;
    final dynamic exp = decoded['exp'];
    final int expSeconds = exp is int ? exp : int.tryParse(exp.toString()) ?? 0;
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expSeconds <= nowSeconds + 60) {
      return false;
    }

    return true;
  }

  // =============================================================
  // SINGLETON
  // =============================================================

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  late final Dio _dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // =============================================================
  // GET
  // =============================================================

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  // =============================================================
  // POST
  // =============================================================

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  // =============================================================
  // PUT
  // =============================================================

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  // =============================================================
  // PATCH
  // =============================================================

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  // =============================================================
  // DELETE
  // =============================================================

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
