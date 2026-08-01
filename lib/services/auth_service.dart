import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Official method to exchange ClientId/Secret for a JWT token (Phase 1).
  Future<AuthResponse> fetchToken(String clientId, String clientSecret) async {
    final response = await _api.post(
      ApiEndpoints.authToken,
      data: {'clientId': clientId, 'clientSecret': clientSecret},
    );

    final auth = AuthResponse.fromJson(response.data);
    if (auth.success && auth.token != null) {
      await _storage.write(key: 'jwt_token', value: auth.token);
      await _storage.write(key: 'api_client_id', value: auth.clientId);
    }
    return auth;
  }

  /// Legacy Tenant Login path.
  Future<AuthResponse> tenantLogin(String email, String password) async {
    final response = await _api.post(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );

    final auth = AuthResponse.fromJson(response.data);
    if (auth.success && auth.token != null) {
      await _storage.write(key: 'jwt_token', value: auth.token);
    }
    return auth;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'resolved_client_uuid');
    await _storage.delete(key: 'api_client_id');
  }

  Future<String?> getSavedToken() => _storage.read(key: 'jwt_token');
}
