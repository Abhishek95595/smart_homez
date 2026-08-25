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
        onRequest: (
          RequestOptions options,
          RequestInterceptorHandler handler,
        ) async {
          try {
            final String path = options.path;

            String? token;

            // =====================================================
            // ALEXA
            // =====================================================
            //
            // Alexa account linking needs the logged-in
            // USER / PLATFORM JWT.
            if (_isAlexaEndpoint(path)) {
              token = await _storage.read(
                key: 'platform_user_jwt',
              );

              debugPrint(
                '[API Auth] Alexa endpoint detected.',
              );

              debugPrint(
                '[API Auth] Platform user JWT exists: '
                '${token != null && token.trim().isNotEmpty}',
              );
            }

            // =====================================================
            // NORMAL BACKEND APIs
            // =====================================================
            else {
              // First try API/service JWT.
              token = await _storage.read(
                key: 'api_service_jwt',
              );

              // Backward compatibility with your current app.
              if (token == null || token.trim().isEmpty) {
                token = await _storage.read(
                  key: 'jwt_token',
                );
              }

              // If service token doesn't exist, try user token.
              if (token == null || token.trim().isEmpty) {
                token = await _storage.read(
                  key: 'platform_user_jwt',
                );
              }
            }

            // =====================================================
            // ATTACH AUTHORIZATION HEADER
            // =====================================================

            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer ${token.trim()}';

              debugPrint(
                '[API Auth] Authorization attached: true',
              );
            } else {
              options.headers.remove('Authorization');

              debugPrint(
                '[API Auth] Authorization attached: false',
              );
            }

            debugPrint(
              '[API Request] ${options.method} ${options.path}',
            );

            return handler.next(options);
          } catch (error) {
            debugPrint(
              '[API Auth] Request interceptor error: $error',
            );

            return handler.next(options);
          }
        },

        onResponse: (
          Response<dynamic> response,
          ResponseInterceptorHandler handler,
        ) {
          debugPrint(
            '[API Response] '
            '${response.statusCode} '
            '${response.requestOptions.path}',
          );

          return handler.next(response);
        },

        onError: (
          DioException error,
          ErrorInterceptorHandler handler,
        ) async {
          final int? statusCode =
              error.response?.statusCode;

          debugPrint(
            '[API Error] '
            '$statusCode '
            '${error.requestOptions.method} '
            '${error.requestOptions.path}',
          );

          if (statusCode == 401) {
            debugPrint(
              '[API Auth] 401 Unauthorized detected. Attempting automatic token refresh...',
            );

            final String path = error.requestOptions.path;
            if (path == ApiEndpoints.authToken || path == ApiEndpoints.authLogin) {
              return handler.next(error);
            }

            try {
              final String? clientId = await _storage.read(key: 'api_client_id');
              final String? clientSecret = await _storage.read(key: 'api_client_secret');
              final String? email = await _storage.read(key: 'login_email');
              final String? password = await _storage.read(key: 'login_password');

              String? newToken;

              if (clientId != null &&
                  clientSecret != null &&
                  clientId.isNotEmpty &&
                  clientSecret.isNotEmpty) {
                debugPrint('[API Auth] Refreshing token via Client API...');
                final Dio refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
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
                  newToken = responseBody['token']?.toString();
                  if (newToken != null && newToken.isNotEmpty) {
                    await _storage.write(key: 'jwt_token', value: newToken);
                    debugPrint('[API Auth] Client API token refreshed successfully.');
                  }
                }
              } else if (email != null &&
                  password != null &&
                  email.isNotEmpty &&
                  password.isNotEmpty) {
                debugPrint('[API Auth] Refreshing token via email/password...');
                final Dio refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
                final response = await refreshDio.post<dynamic>(
                  ApiEndpoints.authLogin,
                  data: <String, dynamic>{
                    'email': email,
                    'password': password,
                  },
                );

                final dynamic responseBody = response.data;
                if (responseBody is Map &&
                    responseBody['success'] == true &&
                    responseBody['token'] != null) {
                  newToken = responseBody['token']?.toString();
                  if (newToken != null && newToken.isNotEmpty) {
                    await _storage.write(key: 'jwt_token', value: newToken);
                    debugPrint('[API Auth] User token refreshed successfully.');
                  }
                }
              }

              if (newToken != null && newToken.isNotEmpty) {
                final RequestOptions options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';

                final Dio retryDio = Dio(
                  BaseOptions(
                    baseUrl: ApiEndpoints.baseUrl,
                    headers: options.headers,
                  ),
                );

                final Response<dynamic> retryResponse = await retryDio.fetch<dynamic>(options);
                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              debugPrint('[API Auth] Automatic token refresh failed: $refreshError');
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // =============================================================
  // SINGLETON
  // =============================================================

  static final ApiClient _instance =
      ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  late final Dio _dio;

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // =============================================================
  // ALEXA ENDPOINT CHECK
  // =============================================================

  static bool _isAlexaEndpoint(String path) {
    return path.startsWith(
      '/api/integrations/alexa/',
    );
  }

  // =============================================================
  // GET
  // =============================================================

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
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