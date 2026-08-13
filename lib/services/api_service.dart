import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

/// Compatibility API service used by repositories.
///
/// This class wraps [ApiClient] and preserves the existing repository API,
/// including the `body:` parameter used throughout TenantApiRepository.
class ApiService {
  ApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.post(
      path,
      data: data ?? body,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.put(
      path,
      data: data ?? body,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.patch(
      path,
      data: data ?? body,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _apiClient.delete(
      path,
      data: data ?? body,
      queryParameters: queryParameters,
    );
  }
}
