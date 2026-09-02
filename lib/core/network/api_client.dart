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

                // If caller explicitly provided an Authorization header, respect it and do not overwrite
                final dynamic existingAuth = options.headers['Authorization'];
                if (existingAuth != null &&
                    existingAuth.toString().trim().isNotEmpty) {
                  debugPrint('[API Request] ${options.method} $path (Using explicit Authorization header)');
                  return handler.next(options);
                }

                String? token;
                if (isAlexa) {
                  token = await _storage.read(key: 'client_api_jwt');
                } else {
                  token = await _storage.read(key: 'platform_user_jwt');
                  if (token == null || token.trim().isEmpty) {
                    token = await _storage.read(key: 'client_api_jwt');
                  }
                }

                if (token == null || token.trim().isEmpty) {
                  token = await _storage.read(key: 'api_service_jwt');
                }
                if (token == null || token.trim().isEmpty) {
                  token = await _storage.read(key: 'jwt_token');
                }

                if (token == null || token.trim().isEmpty) {
                  final String? clientId =
                      await _storage.read(key: 'api_client_id') ??
                      'anvyaaai_AEB3';
                  final String? clientSecret =
                      await _storage.read(key: 'api_client_secret') ??
                      'ZoNiiXT2wfgzFC0tmR8v130byqwRZ7wzGEYhJXENfI8';
                  if (clientId != null && clientSecret != null) {
                    try {
                      final Dio authDio = Dio(
                        BaseOptions(baseUrl: ApiEndpoints.baseUrl),
                      );
                      final res = await authDio.post(
                        ApiEndpoints.authToken,
                        data: {
                          'clientId': clientId,
                          'clientSecret': clientSecret,
                        },
                      );
                      if (res.data is Map && res.data['token'] != null) {
                        token = res.data['token']?.toString();
                        if (token != null && token.isNotEmpty) {
                          await _storage.write(
                            key: 'client_api_jwt',
                            value: token,
                          );
                        }
                      }
                    } catch (_) {}
                  }
                }

                if (token != null && token.trim().isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer ${token.trim()}';
                } else {
                  options.headers.remove('Authorization');
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
          final bool isRetry = error.requestOptions.extra['isRetry'] == true;

          debugPrint(
            '[API Error] '
            '$statusCode '
            '$path',
          );

          if (statusCode == 401 && !isRetry) {
            if (path == ApiEndpoints.authToken ||
                path == ApiEndpoints.authLogin) {
              return handler.next(error);
            }

            try {
              final String? loginEmail = await _storage.read(key: 'login_email');
              final String? loginPassword =
                  await _storage.read(key: 'login_password');

              if (loginEmail != null &&
                  loginEmail.trim().isNotEmpty &&
                  loginPassword != null &&
                  loginPassword.trim().isNotEmpty) {
                debugPrint(
                  '[API Auth] Auto-refreshing user session via login credentials...',
                );
                final Dio refreshDio = Dio(
                  BaseOptions(baseUrl: ApiEndpoints.baseUrl),
                );
                final response = await refreshDio.post<dynamic>(
                  ApiEndpoints.authLogin,
                  data: <String, dynamic>{
                    'email': loginEmail.trim(),
                    'password': loginPassword.trim(),
                  },
                );

                final dynamic responseBody = response.data;
                if (responseBody is Map &&
                    responseBody['success'] == true &&
                    responseBody['token'] != null) {
                  final String? newToken = responseBody['token']?.toString();
                  if (newToken != null && newToken.isNotEmpty) {
                    await _storage.write(
                      key: 'platform_user_jwt',
                      value: newToken,
                    );
                    await _storage.write(
                      key: 'client_api_jwt',
                      value: newToken,
                    );
                    await _storage.write(key: 'jwt_token', value: newToken);

                    final RequestOptions options = error.requestOptions;
                    options.extra['isRetry'] = true;
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

              final String? clientId =
                  await _storage.read(key: 'api_client_id') ?? 'anvyaaai_AEB3';
              final String? clientSecret =
                  await _storage.read(key: 'api_client_secret') ??
                  'ZoNiiXT2wfgzFC0tmR8v130byqwRZ7wzGEYhJXENfI8';

              if (clientId != null &&
                  clientId.trim().isNotEmpty &&
                  clientSecret != null &&
                  clientSecret.trim().isNotEmpty) {
                debugPrint(
                  '[API Auth] Single refresh retry for Client API token...',
                );
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

                    final RequestOptions options = error.requestOptions;
                    options.extra['isRetry'] = true;
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
                '[API Auth] Token auto-refresh attempt failed: $refreshError',
              );
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
