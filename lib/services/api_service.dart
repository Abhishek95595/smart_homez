import 'dart:convert';
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

  Future<Map<String, String>> _headers() async {
    String? authHeader;
    if (_token != null) {
      authHeader = 'Bearer $_token';
    } else if (_clientId != null && _clientSecret != null) {
      // Fallback for special Bearer format supported by this backend
      authHeader = 'Bearer $_clientId:$_clientSecret';
    }

    return {
      'Content-Type': 'application/json',
      if (authHeader != null) 'Authorization': authHeader,
    };
  }

  Future<http.Response> post(String path, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && _clientId != null && _clientSecret != null && _token != null) {
      // Token expired, clear it and retry with credentials fallback
      _token = null;
      return post(path, body);
    }
    return response;
  }

  Future<http.Response> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );

    if (response.statusCode == 401 && _clientId != null && _clientSecret != null && _token != null) {
      _token = null;
      return get(path);
    }
    return response;
  }

  Future<String?> login(String id, String secret) async {
    _clientId = id;
    _clientSecret = secret;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': id, 'password': secret}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          _token = data['token'];
          return _token;
        }
      }
    } catch (_) {
      // Network error or other issues
    }
    
    // Return null to trigger fallback in AuthProvider or Repository
    return null;
  }
}
