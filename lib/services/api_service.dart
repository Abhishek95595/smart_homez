import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://tenant-api.saajsajja.in';
  String? _token;
  String? _clientId;
  String? _clientSecret;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  void setCredentials(String id, String secret) {
    _clientId = id;
    _clientSecret = secret;
  }

  void setToken(String token) {
    _token = token;
  }

  bool get isAuthenticated => _token != null || (_clientId != null && _clientSecret != null);

  Future<Map<String, String>> _headers({bool forceMasterKey = false}) async {
    String? authHeader;
    
    // Priority: 1. Force Master Key, 2. JWT Token, 3. Master Key Fallback
    if (forceMasterKey && _clientId != null && _clientSecret != null) {
      authHeader = 'Bearer $_clientId:$_clientSecret';
    } else if (_token != null) {
      authHeader = 'Bearer $_token';
    } else if (_clientId != null && _clientSecret != null) {
      authHeader = 'Bearer $_clientId:$_clientSecret';
    }

    return {
      'Content-Type': 'application/json',
      if (authHeader != null) 'Authorization': authHeader,
    };
  }

  Future<http.Response> post(String path, dynamic body, {bool isRetry = false}) async {
    final url = '$baseUrl$path';
    // For specific discovery endpoints, we might want to try master key on retry
    final bool useMasterKey = isRetry && (path.contains('/clients/resolve') || path.contains('/clients'));
    final headers = await _headers(forceMasterKey: useMasterKey);
    
    debugPrint('[API Request] POST $url ${useMasterKey ? "(Master Key)" : ""}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('[API Response] ${response.statusCode} | ${response.body}');

      if (response.statusCode == 401 && !isRetry) {
        if (_clientId != null && _clientSecret != null) {
          debugPrint('[API Auth] 401 Unauthorized. Attempting fallback/refresh...');
          // For login path, don't retry as master key won't help there
          if (path.contains('/api/Auth/login')) return response;
          
          return post(path, body, isRetry: true);
        }
      }
      return response;
    } catch (e) {
      debugPrint('[API Error] POST $url failed: $e');
      rethrow;
    }
  }

  Future<http.Response> get(String path, {bool isRetry = false}) async {
    final url = '$baseUrl$path';
    final bool useMasterKey = isRetry; // Try master key on any GET 401
    final headers = await _headers(forceMasterKey: useMasterKey);

    debugPrint('[API Request] GET $url ${useMasterKey ? "(Master Key)" : ""}');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('[API Response] ${response.statusCode} | ${response.body}');

      if (response.statusCode == 401 && !isRetry) {
        if (_clientId != null && _clientSecret != null) {
          debugPrint('[API Auth] 401 Unauthorized. Attempting master key fallback...');
          return get(path, isRetry: true);
        }
      }
      return response;
    } catch (e) {
      debugPrint('[API Error] GET $url failed: $e');
      rethrow;
    }
  }

  Future<String?> login(String id, String secret) async {
    _clientId = id;
    _clientSecret = secret;
    
    debugPrint('[API Login] Attempting JWT login for $id');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': id, 'password': secret}),
      );

      debugPrint('[API Login Response] ${response.statusCode} | ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          _token = data['token'];
          return _token;
        }
      }
    } catch (e) {
      debugPrint('[API Login Error] $e');
    }
    
    return null;
  }
}
