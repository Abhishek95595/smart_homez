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
    UserRole targetRole, {
    required PropertyProvider propertyProvider,
    required DeviceProvider deviceProvider,
  }) async {
    try {
      bool isEmail = identifier.contains('@');

      // Phase 1: Authentication
      final authResponse = isEmail
          ? await _authService.tenantLogin(identifier, secret)
          : await _authService.fetchToken(identifier, secret);

      if (!authResponse.success || authResponse.token == null) {
        return authResponse.error ??
            'Authentication failed. Please check your credentials.';
      }

      _apiToken = authResponse.token;

      // Phase 2: Client Resolution
      final resolvedClient = await _clientService.resolveClient(
        email: isEmail ? identifier : 'app_user@aurabrain.com',
        name: authResponse.clientName ?? 'Smart Homz User',
      );

      if (resolvedClient == null) {
        return 'Could not verify identity. Please contact support.';
      }

      // Fix 2: Explicitly store and use the resolved UUID, not the login ID
      _resolvedClientUuid = resolvedClient.id;

      // Defensive Initials Generation
      final String displayName =
          resolvedClient.name ?? authResponse.clientName ?? 'User';
      String initials = 'US';
      if (displayName.trim().isNotEmpty) {
        final parts = displayName.trim().split(' ');
        if (parts.length >= 2) {
          initials = (parts[0][0] + parts[1][0]).toUpperCase();
        } else if (parts[0].length >= 2) {
          initials = parts[0].substring(0, 2).toUpperCase();
        } else {
          initials = parts[0][0].toUpperCase();
        }
      }

      _currentUser = AppUser(
        id: resolvedClient.id,
        name: displayName,
        email: resolvedClient.email ?? (isEmail ? identifier : ''),
        phone: resolvedClient.phone ?? '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: initials,
      );

      // Trigger Hierarchy Sync using the real UUID
      // Fix 3: These calls update state, but they are NOT in a build method here.
      // We will ensure the caller (LoginScreen) handles the navigation.
      propertyProvider.setClientId(resolvedClient.id);
      await propertyProvider.syncFromApi(resolvedClient.id);
      await deviceProvider.syncFromApi(resolvedClient.id);

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('[Auth Error] $e');
      final String msg = e.toString();
      if (msg.contains('401')) return 'Invalid credentials. Please try again.';
      if (msg.contains('404')) return 'Account setup incomplete on backend.';
      return msg.startsWith('ApiException:')
          ? msg.replaceFirst('ApiException: ', '')
          : msg;
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
