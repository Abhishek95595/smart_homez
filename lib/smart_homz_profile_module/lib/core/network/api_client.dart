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
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              try {
                final String path = options.path;
                final bool isAlexa = _isAlexaEndpoint(path);

                String? token;

                if (isAlexa) {
                  token = await _storage.read(key: 'platform_user_jwt');
                  if (token == null || token.trim().isEmpty) {
                    token = await _storage.read(key: 'jwt_token');
                  }
                  debugPrint('[API Auth] Alexa endpoint detected.');
                  debugPrint(
                    '[API Auth] Platform user JWT exists: '
                    '${token != null && token.trim().isNotEmpty}',
                  );
                  if (token != null && token.trim().isNotEmpty) {
                    _logJwtClaims(token.trim());
                  }
                } else {
                  token = await _storage.read(key: 'client_api_jwt');
                  if (token == null || token.trim().isEmpty) {
                    token = await _storage.read(key: 'api_service_jwt');
                  }
                  if (token == null || token.trim().isEmpty) {
                    token = await _storage.read(key: 'jwt_token');
                  }
                  if (token == null || token.trim().isEmpty) {
                    token = await _storage.read(key: 'platform_user_jwt');
                  }
                }

                if (token != null && token.trim().isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer ${token.trim()}';
                  debugPrint('[API Auth] Authorization attached: true');
                } else {
                  options.headers.remove('Authorization');
                  debugPrint('[API Auth] Authorization attached: false');
                }

                debugPrint('[API Request] ${options.method} ${options.path}');
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
          final bool isAlexa = _isAlexaEndpoint(path);

          debugPrint(
            '[API Error] '
            '$statusCode '
            '$path '
            '${error.message}',
          );

          if (statusCode == 401) {
            if (isAlexa) {
              debugPrint(
                '[API Auth] 401 Unauthorized on Alexa endpoint. Skipping Client API token refresh to prevent wrong token type retry.',
              );
              return handler.next(error);
            }

            if (path == ApiEndpoints.authToken ||
                path == ApiEndpoints.authLogin) {
              return handler.next(error);
            }

            try {
              String? clientId = await _storage.read(key: 'api_client_id');
              String? clientSecret = await _storage.read(
                key: 'api_client_secret',
              );

              if (clientId == null ||
                  clientId.trim().isEmpty ||
                  clientSecret == null ||
                  clientSecret.trim().isEmpty) {
                clientId = 'anvyaaai_AEB3';
                clientSecret = 'ZoNiiXT2wfgzFC0tmR8v130byqwRZ7wzGEYhJXENfI8';
              }

              if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
                debugPrint('[API Auth] Refreshing token via Client API...');
                final Dio refreshDio = Dio(
                  BaseOptions(baseUrl: ApiEndpoints.baseUrl),
                );
                final response = await refreshDio.post<dynamic>(
                  ApiEndpoints.authToken,
                  data: <String, dynamic>{
                    'clientId': clientId,
                    'clientSecret': clientSecret,
                  },
                );

                final dynamic responseBody = response.data;
                if (responseBody is Map &&
                    responseBody['success'] == true &&
                    responseBody['token'] != null) {
                  final String? newToken = responseBody['token']?.toString();
                  if (newToken != null && newToken.isNotEmpty) {
                    await _storage.write(
                      key: 'client_api_jwt',
                      value: newToken,
                    );
                    await _storage.write(
                      key: 'api_service_jwt',
                      value: newToken,
                    );
                    await _storage.write(key: 'jwt_token', value: newToken);
                    debugPrint(
                      '[API Auth] Client API token refreshed successfully.',
                    );

                    final RequestOptions options = error.requestOptions;
                    options.headers['Authorization'] = 'Bearer $newToken';
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
                }
              }
            } catch (refreshError) {
              debugPrint(
                '[API Auth] Automatic token refresh failed: $refreshError',
              );
            }
          }

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
