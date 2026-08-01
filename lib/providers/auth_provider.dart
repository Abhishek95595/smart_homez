import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import '../services/tenant_api_repository.dart';
import 'device_provider.dart';
import 'property_provider.dart';

/// Handles login/session state.
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

  /// Authenticate with the real backend API using the refined Dio flow.
  Future<String?> loginWithApi(
    String email, 
    String password, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    try {
      // 1. Attempt Official Token Exchange (Preferred for ClientId:Secret)
      bool success = await _apiService.fetchToken(email, password);
      
      String? apiClientId;
      String? apiClientName;
      String? userType;

      if (!success) {
        // Fallback to Mobile Login if direct token exchange fails
        final response = await _apiService.mobileLogin(email, password);
        if (response.statusCode == 200 && response.data['success'] == true) {
          success = true;
          apiClientId = response.data['clientId'];
          apiClientName = response.data['clientName'];
          userType = response.data['userType'];
        }
      }

      if (!success) {
        return 'Login failed. Please check your Client ID and Secret.';
      }

      // Set credentials for background refresh
      _apiService.setCredentials(email, password);
      
      // 2. Handle Identity Resolution
      // If we don't have IDs from the login response, try resolving
      String finalId = apiClientId ?? '';
      String finalName = apiClientName ?? 'Smart Homez Manager';
      
      if (finalId.isEmpty) {
        debugPrint('[Auth] No clientId in login response. Attempting to resolve via API...');
        final resolveResponse = await _apiRepo.resolveClient(
          email: email, 
          name: 'Smart Homez Manager',
        );
        
        if (resolveResponse != null) {
          finalId = resolveResponse.id;
          finalName = resolveResponse.name ?? finalName;
        } else if (userType == 'Tenant' || email.contains('anvya')) {
          // Fallback for Tenant accounts or specific test accounts
          debugPrint('[Auth] Client resolution skipped/failed. Using account identity.');
          finalId = email; 
          finalName = apiClientName ?? 'App Manager';
        } else {
          return 'Could not verify client identity. Please contact support.';
        }
      }
      
      _resolvedClientId = finalId;
      
      // 3. Update the user profile
      _currentUser = AppUser(
        id: finalId,
        name: finalName,
        email: email,
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: finalName.length >= 2 ? finalName.substring(0, 2).toUpperCase() : 'AM',
      );

      // 4. Trigger Automatic Sync
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
