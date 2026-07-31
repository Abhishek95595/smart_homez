import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import '../services/tenant_api_repository.dart';
import 'device_provider.dart';
import 'property_provider.dart';

/// Handles login/session state. In production this will call the
/// Auth API (login/signup/token refresh) described in the PRD.
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  String? _token;
  String? _resolvedClientId;
  final ApiService _apiService = ApiService();
  final TenantApiRepository _apiRepo = TenantApiRepository();

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole get role => _currentUser?.role ?? UserRole.resident;
  String? get token => _token;
  String? get resolvedClientId => _resolvedClientId;

  /// Authenticate with the real backend API.
  /// Returns null on success, or an error message on failure.
  Future<String?> loginWithApi(
    String clientId, 
    String clientSecret, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    try {
      // 1. Set credentials in service
      _apiService.setCredentials(clientId, clientSecret);
      
      // 2. Attempt real login (JWT)
      final loginResponse = await _baseUrlPost('/api/Auth/login', {'email': clientId, 'password': clientSecret});
      
      if (loginResponse.statusCode != 200) {
        return 'Login failed. Please check your credentials.';
      }

      final loginData = jsonDecode(loginResponse.body);
      if (loginData['success'] != true || loginData['token'] == null) {
        return loginData['error'] ?? 'Login failed. Please check your credentials.';
      }

      final String token = loginData['token'];
      final String? apiClientId = loginData['clientId'];
      final String? apiClientName = loginData['clientName'];
      final String? userType = loginData['userType'];

      _token = token;
      _apiService.setToken(token);
      
      // 3. Handle Identity Resolution
      String finalId = apiClientId ?? '';
      String finalName = apiClientName ?? 'Smart Homez Manager';
      
      if (finalId.isEmpty) {
        debugPrint('[Auth] No clientId in login response. Attempting to resolve via API...');
        final resolveResponse = await _apiRepo.resolveClient(
          email: clientId, 
          name: 'Smart Homez Manager',
        );
        
        if (resolveResponse != null) {
          finalId = resolveResponse.id;
          finalName = resolveResponse.name ?? finalName;
        } else if (userType == 'Tenant') {
          // If we can't resolve but we are a Tenant, use a fallback scope
          debugPrint('[Auth] Client resolution failed for Tenant. Using fallback scope.');
          finalId = 'tenant_root'; 
        } else {
          return 'Could not verify client identity. Please contact support.';
        }
      }
      
      _resolvedClientId = finalId;
      
      // 4. Update the user profile
      _currentUser = AppUser(
        id: finalId,
        name: finalName,
        email: clientId,
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: finalName.length >= 2 ? finalName.substring(0, 2).toUpperCase() : 'AM',
      );

      // 5. Trigger Automatic Sync (Graceful)
      propertyProvider.setClientId(finalId);
      try {
        await propertyProvider.syncFromApi(finalId);
        await deviceProvider.syncFromApi(finalId);
      } catch (syncError) {
        debugPrint('[Auth Sync Error] $syncError');
        // We still allow login even if sync fails partially
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('[Auth Provider Error] $e');
      return 'Connection Error: ${e.toString().split('\n').first}';
    }
  }

  Future<http.Response> _baseUrlPost(String path, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('${_apiService.baseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  /// Simulated login: pick a demo user by role.
  Future<void> loginAs(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final users = MockData.demoUsers();
    _currentUser = users.firstWhere(
      (u) => u.role == role,
      orElse: () => users.first,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _resolvedClientId = null;
    _apiService.setToken('');
    notifyListeners();
  }
}
