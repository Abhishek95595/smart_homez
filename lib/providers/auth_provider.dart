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
  Future<bool> loginWithApi(
    String clientId, 
    String clientSecret, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    // 1. Set credentials in service
    _apiService.setCredentials(clientId, clientSecret);
    
    // 2. Attempt real login
    final token = await _apiService.login(clientId, clientSecret);
    if (token != null) {
      _token = token;
    }
    
    // 3. Resolve the client to verify credentials and get an ID
    final response = await _apiRepo.resolveClient(
      email: 'app_user@aurabrain.com', 
      name: 'Smart Homez Manager',
    );
    
    if (response != null) {
      _resolvedClientId = response.id;
      
      // Update the mock user profile with real data and the selected role
      _currentUser = AppUser(
        id: response.id,
        name: response.name ?? 'App Manager',
        email: response.email ?? clientId,
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: response.name != null ? response.name!.substring(0, 2).toUpperCase() : 'AM',
      );

      // 4. Trigger Automatic Sync
      propertyProvider.setClientId(response.id);
      await propertyProvider.syncFromApi(response.id);
      await deviceProvider.syncFromApi(response.id);

      notifyListeners();
      return true;
    }
    
    return false;
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
