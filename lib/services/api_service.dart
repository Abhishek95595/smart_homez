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

  bool get isAuthenticated => _token != null;

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<http.Response> post(String path, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && _clientId != null && _clientSecret != null) {
      // Token might be expired, try to login again
      await login(_clientId!, _clientSecret!);
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );

    if (response.statusCode == 401 && _clientId != null && _clientSecret != null) {
      await login(_clientId!, _clientSecret!);
      return http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      );
    }
    return response;
  }

  Future<String?> login(String id, String secret) async {
    _clientId = id;
    _clientSecret = secret;
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': id, 'password': secret}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return _token;
    }
    return null;
  }
}
