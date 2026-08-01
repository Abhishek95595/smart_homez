import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = 'https://tenant-api.saajsajja.in';
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String? _clientId;
  String? _clientSecret;
  String? _cachedToken;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          _cachedToken = token;
        }
        debugPrint('[API Request] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API Response] ${response.statusCode} | ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint('[API Error] ${e.type} | ${e.message}');
        
        if (e.response?.statusCode == 401 && _clientId != null && _clientSecret != null) {
          debugPrint('[API Auth] 401 Unauthorized. Attempting automatic token refresh...');
          
          final success = await fetchToken(_clientId!, _clientSecret!);
          if (success) {
            debugPrint('[API Auth] Token refreshed, retrying original request...');
            
            final newToken = await _storage.read(key: 'jwt_token');
            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            
            final response = await _dio.fetch(options);
            return handler.resolve(response);
          }
        }
        return handler.next(e);
      },
    ));
  }

  void setCredentials(String id, String secret) {
    _clientId = id;
    _clientSecret = secret;
  }

  String? get token => _cachedToken;

  Future<Response> post(String path, dynamic body) => _dio.post(path, data: body);
  Future<Response> get(String path) => _dio.get(path);

  Future<Response> mobileLogin(String email, String password) async {
    final response = await _dio.post('/api/v1/mobile/login', data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final token = response.data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        _cachedToken = token;
      }
    }
    return response;
  }

  Future<bool> fetchToken(String clientId, String clientSecret) async {
    _clientId = clientId;
    _clientSecret = clientSecret;

    try {
      final response = await _dio.post('/api/Auth/token', data: {
        'clientId': clientId,
        'clientSecret': clientSecret,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        if (token != null) {
          await _storage.write(key: 'jwt_token', value: token);
          _cachedToken = token;
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API Token Exchange Error] $e');
    }
    return false;
  }

  Future<Response> login(String email, String password) async {
    final response = await _dio.post('/api/Auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final token = response.data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
        _cachedToken = token;
      }
    }
    return response;
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: 'jwt_token');
    _cachedToken = null;
    _clientId = null;
    _clientSecret = null;
  }
}
