import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import 'device_provider.dart';
import 'property_provider.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  String? _resolvedClientUuid;
  String? _apiToken;
  
  final AuthService _authService = AuthService();
  final ClientService _clientService = ClientService();

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole get role => _currentUser?.role ?? UserRole.resident;
  String? get resolvedClientUuid => _resolvedClientUuid;
  
  // Compatibility getters for existing code
  String? get token => _apiToken;
  String? get resolvedClientId => _resolvedClientUuid;

  /// Combined Auth + Resolve Flow (Phases 1 & 2)
  Future<String?> loginWithApi(
    String identifier, 
    String secret, 
    UserRole targetRole,
    {required PropertyProvider propertyProvider, required DeviceProvider deviceProvider}
  ) async {
    try {
      bool isEmail = identifier.contains('@');
      
      // Phase 1: Authentication
      final authResponse = isEmail 
          ? await _authService.tenantLogin(identifier, secret)
          : await _authService.fetchToken(identifier, secret);

      if (!authResponse.success || authResponse.token == null) {
        return authResponse.error ?? 'Authentication failed. Please check your credentials.';
      }

      _apiToken = authResponse.token;

      // Phase 2: Client Resolution
      final resolvedClient = await _clientService.resolveClient(
        email: isEmail ? identifier : 'app_user@aurabrain.com',
        name: authResponse.clientName ?? 'Smart Homz User',
      );

      if (resolvedClient == null) {
        return 'Could not resolve client identity. Please contact support.';
      }

      _resolvedClientUuid = resolvedClient.id;
      
      _currentUser = AppUser(
        id: resolvedClient.id,
        name: resolvedClient.name ?? authResponse.clientName ?? 'User',
        email: resolvedClient.email ?? (isEmail ? identifier : ''),
        phone: resolvedClient.phone ?? '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: (resolvedClient.name ?? 'AM').substring(0, 2).toUpperCase(),
      );

      // Trigger Hierarchy Sync using the real UUID
      propertyProvider.setClientId(resolvedClient.id);
      await propertyProvider.syncFromApi(resolvedClient.id);
      await deviceProvider.syncFromApi(resolvedClient.id);

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('[Auth Error] $e');
      return e.toString();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _resolvedClientUuid = null;
    _apiToken = null;
    await _authService.logout();
    notifyListeners();
  }
}
