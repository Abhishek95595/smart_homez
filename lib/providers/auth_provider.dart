import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import '../services/tenant_api_repository.dart';

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
  Future<bool> loginWithApi(String clientId, String clientSecret) async {
    final token = await _apiService.login(clientId, clientSecret);
    if (token != null) {
      _token = token;
      
      // After login, resolve the client to get an ID
      final response = await _apiRepo.resolveClient(
        email: clientId, // Using email as clientId for now
        name: 'App Manager',
      );
      
      if (response != null) {
        _resolvedClientId = response.id;
      }

      // Keep using a mock user for UI roles for now, but linked to API session
      final users = MockData.demoUsers();
      _currentUser = users.first; // Default to admin for API sessions

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
