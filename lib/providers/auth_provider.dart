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

  /// Authenticate with the real backend API using the /api/Auth/token exchange flow.
  /// Returns null on success, or an error message on failure.
  Future<String?> loginWithApi(
    String clientId, 
    String clientSecret, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    try {
      // 1. Exchange ClientId/Secret for JWT token (Official Flow)
      final success = await _apiService.fetchToken(clientId, clientSecret);
      
      if (!success) {
        // Fallback: Try the legacy login if token exchange fails
        final legacyToken = await _apiService.login(clientId, clientSecret);
        if (legacyToken == null) {
          return 'Authentication failed. Please check your Client ID and Secret.';
        }
      }

      // 2. Resolve the client identity using the fresh token
      final resolveResponse = await _apiRepo.resolveClient(
        email: 'app_user@aurabrain.com', 
        name: 'Smart Homez Manager',
      );
      
      String finalId = '';
      String finalName = '';
      
      if (resolveResponse != null) {
        finalId = resolveResponse.id;
        finalName = resolveResponse.name ?? 'App Manager';
      } else {
        // Fallback for Tenant accounts that might not have a specific clientId
        finalName = 'Smart Homez Manager';
        finalId = 'tenant_root'; 
      }
      
      _resolvedClientId = finalId;
      
      // 3. Update the user profile
      _currentUser = AppUser(
        id: finalId,
        name: finalName,
        email: clientId,
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: finalName.length >= 2 ? finalName.substring(0, 2).toUpperCase() : 'AM',
      );

      // 4. Trigger Automatic Sync (Graceful)
      propertyProvider.setClientId(finalId);
      try {
        await propertyProvider.syncFromApi(finalId);
        await deviceProvider.syncFromApi(finalId);
      } catch (syncError) {
        debugPrint('[Auth Sync Error] $syncError');
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('[Auth Provider Error] $e');
      return 'Connection Error: ${e.toString().split('\n').first}';
    }
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
