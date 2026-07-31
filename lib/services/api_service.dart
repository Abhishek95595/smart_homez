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

  bool get isAuthenticated => _token != null;

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<http.Response> post(String path, dynamic body) async {
    final url = '$baseUrl$path';
    final headers = await _headers();
    
    debugPrint('[API Request] POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('[API Response] ${response.statusCode} | ${response.body}');

      if (response.statusCode == 401 && _clientId != null && _clientSecret != null) {
        debugPrint('[API Auth] 401 Unauthorized. Attempting token refresh...');
        final newToken = await login(_clientId!, _clientSecret!);
        if (newToken != null) {
          debugPrint('[API Auth] Token refreshed, retrying original request...');
          return post(path, body);
        }
      }
      return response;
    } catch (e) {
      debugPrint('[API Error] POST $url failed: $e');
      rethrow;
    }
  }

  Future<http.Response> get(String path) async {
    final url = '$baseUrl$path';
    final headers = await _headers();

    debugPrint('[API Request] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('[API Response] ${response.statusCode} | ${response.body}');

      if (response.statusCode == 401 && _clientId != null && _clientSecret != null) {
        debugPrint('[API Auth] 401 Unauthorized. Attempting token refresh...');
        final newToken = await login(_clientId!, _clientSecret!);
        if (newToken != null) {
          debugPrint('[API Auth] Token refreshed, retrying original request...');
          return get(path);
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
