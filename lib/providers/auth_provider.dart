import 'dart:convert';
import 'package:flutter/material.dart';

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
      final token = await _apiService.login(clientId, clientSecret);
      if (token == null) {
        return 'Login failed. Please check your credentials.';
      }
      _token = token;
      
      // 3. Resolve the client or use login response data
      // For Tenant types, we use the clientName from the login response if resolve fails or clientId is null
      final resolveResponse = await _apiRepo.resolveClient(
        email: clientId, 
        name: 'Smart Homez Manager',
      );
      
      String finalId = '';
      String finalName = '';
      
      if (resolveResponse != null) {
        finalId = resolveResponse.id;
        finalName = resolveResponse.name ?? 'App Manager';
      } else {
        // Fallback: Try to extract from the JWT token or use defaults if resolve failed but login succeeded
        finalName = 'Smart Homez Manager';
        finalId = 'tenant_root'; // Default ID for root tenants if not resolvable
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

      // 5. Trigger Automatic Sync
      propertyProvider.setClientId(finalId);
      await propertyProvider.syncFromApi(finalId);
      await deviceProvider.syncFromApi(finalId);

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
    notifyListeners();
  }
}
