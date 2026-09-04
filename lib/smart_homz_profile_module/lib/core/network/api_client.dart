import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
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

            String? token = await _storage.read(key: 'tenant_api_jwt');
            if (!isJwtValid(token)) {
              final String? legacy = await _storage.read(key: 'client_api_jwt');
              if (isJwtValid(legacy)) {
                token = legacy;
                await _storage.write(key: 'tenant_api_jwt', value: token);
              }
              await _storage.delete(key: 'client_api_jwt');
            }

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

          debugPrint(
            '[API Error] '
            '$statusCode '
            '$path '
            '${error.message}',
          );

          return handler.next(error);
        },
      ),
    );
  }

  static void _logJwtClaims(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length == 3) {
        final String normalized = base64Url.normalize(parts[1]);
        final String payloadString = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> claims =
            jsonDecode(payloadString) as Map<String, dynamic>;

        debugPrint('[API Auth JWT Claims] keys: ${claims.keys.toList()}');
        debugPrint('[API Auth JWT Claims] sub: ${claims['sub']}');
        debugPrint('[API Auth JWT Claims] userId: ${claims['userId']}');
        debugPrint('[API Auth JWT Claims] uid: ${claims['uid']}');
        debugPrint(
          '[API Auth JWT Claims] nameidentifier: ${claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']}',
        );
        debugPrint(
          '[API Auth JWT Claims] aud: ${claims['aud']}, iss: ${claims['iss']}, exp: ${claims['exp']}',
        );
      }
    } catch (e) {
      debugPrint('[API Auth JWT Claims] Unable to parse claims: $e');
    }
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

  static bool isJwtValid(String? token) {
    if (token == null || token.trim().isEmpty) return false;
    final List<String> parts = token.trim().split('.');
    if (parts.length != 3) return false;
    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payloadString = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payloadString);
      if (decoded is Map) {
        // 1. Reject Firebase ID tokens & verify AuraBrain issuer
        final dynamic iss = decoded['iss'];
        if (iss == null ||
            iss.toString().contains('securetoken.google.com') ||
            iss.toString() != 'AuraBrain') {
          return false;
        }

        // 2. Verify Audience
        final dynamic aud = decoded['aud'];
        if (aud == null || aud.toString() != 'AuraBrainMobile') {
          return false;
        }

        // 3. Verify Production Tenant ID
        final dynamic tenantId = decoded['TenantId'] ?? decoded['tenantId'];
        if (tenantId == null ||
            tenantId.toString() != '6d11e924-d046-400d-bc30-62a06e13de61') {
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
        if (permission == null || permission.toString() != 'write') {
          return false;
        }

        // 6. Verify Expiration
        if (decoded['exp'] == null) return false;
        final dynamic exp = decoded['exp'];
        final int expSeconds = exp is int
            ? exp
            : int.tryParse(exp.toString()) ?? 0;
        final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expSeconds <= nowSeconds) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // =============================================================
  // ALEXA ENDPOINT CHECK
  // =============================================================

  static bool _isAlexaEndpoint(String path) {
    return path.startsWith('/api/integrations/alexa/');
  }

  // =============================================================
  // GET
  // =============================================================

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(path, queryParameters: queryParameters);
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
  }) async {
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
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
  }) async {
    try {
      return await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
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
  }) async {
    try {
      return await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
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
  }) async {
    try {
      return await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
