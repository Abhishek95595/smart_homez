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
              final String? token = await _storage.read(key: 'jwt_token');

              if (token != null && token.trim().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer ${token.trim()}';
              }

              debugPrint('[API Request] ${options.method} ${options.path}');

              return handler.next(options);
            },
        onResponse:
            (Response<dynamic> response, ResponseInterceptorHandler handler) {
              debugPrint(
                '[API Response] ${response.statusCode} '
                '${response.requestOptions.path}',
              );

              return handler.next(response);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          final int? statusCode = error.response?.statusCode;

          debugPrint(
            '[API Error] $statusCode '
            '${error.requestOptions.method} '
            '${error.requestOptions.path}',
          );

          if (statusCode == 401) {
            debugPrint('[API Auth] 401 Unauthorized detected.');
          }

          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  late final Dio _dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
