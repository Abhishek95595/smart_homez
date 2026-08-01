import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import '../services/tenant_api_repository.dart';
import 'device_provider.dart';
import 'property_provider.dart';

/// Handles login/session state, supporting both Tenant and Client login paths.
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  String? _resolvedClientId;
  final ApiService _apiService = ApiService();
  final TenantApiRepository _apiRepo = TenantApiRepository();

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole get role => _currentUser?.role ?? UserRole.resident;
  String? get resolvedClientId => _resolvedClientId;
  String? get token => _apiService.token;

  /// Authenticate with the real backend API.
  /// Supports: 
  /// 1. Client Credentials (clientId/clientSecret) -> /api/Auth/token
  /// 2. Tenant Credentials (email/password) -> /api/Auth/login
  Future<String?> loginWithApi(
    String identifier, 
    String secret, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    try {
      bool isEmail = identifier.contains('@');
      bool loginSuccess = false;
      String? apiClientId;
      String? apiClientName;
      String? userType;

      if (isEmail) {
        // Path A: Tenant Login (email/password)
        debugPrint('[Auth] Attempting Tenant login for $identifier');
        final response = await _apiService.login(identifier, secret);
        if (response.statusCode == 200 && response.data['success'] == true) {
          loginSuccess = true;
          // Root tenants often don't have a specific clientId in the response
          apiClientId = response.data['clientId'] ?? response.data['tenantId'];
          apiClientName = response.data['clientName'] ?? identifier;
          userType = response.data['userType'];
        }
      } else {
        // Path B: Client Token Exchange (ID/Secret)
        debugPrint('[Auth] Attempting Client token exchange for $identifier');
        loginSuccess = await _apiService.fetchToken(identifier, secret);
        if (loginSuccess) {
          // Token exchange usually returns basic client info in some versions, 
          // but we'll try to resolve more details if needed below.
          apiClientId = identifier; 
          apiClientName = 'Client App';
        }
      }

      if (!loginSuccess) {
        return 'Login failed. Please check your ${isEmail ? "Email" : "Client ID"} and Secret.';
      }

      // Store credentials for background auto-refresh
      _apiService.setCredentials(identifier, secret);
      
      // 2. Resolve final Identity and Scoping ID
      String finalId = apiClientId ?? '';
      String finalName = apiClientName ?? 'Smart Homez Manager';
      
      // If we don't have a solid ID yet, try resolving via the API
      if (finalId.isEmpty || finalId == identifier) {
        debugPrint('[Auth] Resolving client identity for $identifier...');
        final resolveResponse = await _apiRepo.resolveClient(
          email: isEmail ? identifier : null,
          name: 'Smart Homez Manager',
        );
        
        if (resolveResponse != null) {
          finalId = resolveResponse.id;
          finalName = resolveResponse.name ?? finalName;
        } else if (isEmail || userType == 'Tenant') {
          // Fallback: use identifier as ID for scoping if resolution fails but it's a root account
          finalId = identifier;
        } else {
          return 'Could not verify identity. Please contact support.';
        }
      }
      
      _resolvedClientId = finalId;
      
      // 3. Create Session Profile
      _currentUser = AppUser(
        id: finalId,
        name: finalName,
        email: isEmail ? identifier : '',
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: finalName.length >= 2 ? finalName.substring(0, 2).toUpperCase() : 'AM',
      );

      // 4. Trigger Reactive Sync
      propertyProvider.setClientId(finalId);
      try {
        await propertyProvider.syncFromApi(finalId);
        // Start real-time sync with the fresh token
        if (_apiService.token != null) {
          deviceProvider.startRealtime(_apiService.token!);
        }
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

  void logout() async {
    _currentUser = null;
    _resolvedClientId = null;
    await _apiService.clearAuth();
    notifyListeners();
  }
}
