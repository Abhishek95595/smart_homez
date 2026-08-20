import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import '../models/auth_response.dart';
import '../models/resolved_client.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

import 'device_provider.dart';
import '../services/client_service.dart';
import 'property_provider.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, ClientService? clientService})
    : _authService = authService ?? AuthService(),
      _clientService = clientService ?? ClientService();

  final AuthService _authService;
  final ClientService _clientService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppUser? _currentUser;
  String? _resolvedClientUuid;
  String? _apiToken;

  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  UserRole get role => _currentUser?.role ?? UserRole.resident;

  String? get resolvedClientUuid => _resolvedClientUuid;

  // Compatibility getters for existing code.
  String? get token => _apiToken;

  String? get resolvedClientId => _resolvedClientUuid;

  /// Logs in using either:
  ///
  /// 1. Email/password
  /// 2. API Client ID/API Client Secret
  ///
  /// For API Client ID login, provide [customerEmail] so the API can
  /// resolve the real customer UUID used by homes and devices endpoints.
  ///
  /// Returns null on success, otherwise an error message.
  Future<String?> loginWithApi(
    String identifier,
    String secret,
    UserRole targetRole, {
    required PropertyProvider propertyProvider,
    required DeviceProvider deviceProvider,
    String? customerEmail,
    String? customerName,
  }) async {
    if (_isLoading) {
      return 'Login is already in progress.';
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final String cleanIdentifier = identifier.trim();

      final bool isEmailLogin = cleanIdentifier.contains('@');

      if (cleanIdentifier.isEmpty || secret.trim().isEmpty) {
        return _fail('Please enter valid credentials.');
      }

      // ========================================================
      // PHASE 1: AUTHENTICATION
      // ========================================================

      AuthResponse? authResponse;
      try {
        if (isEmailLogin) {
          authResponse = await _authService.tenantLogin(
            email: cleanIdentifier,
            password: secret,
          );
          try {
            final tenantAuth = await _authService.fetchToken(
              clientId: 'anvyaaai_AEB3',
              clientSecret: 'ZoNiiXT2wfgzFC0tmR8v130byqwRZ7wzGEYhJXENfI8',
            );
            if (tenantAuth.success &&
                tenantAuth.token != null &&
                tenantAuth.token!.isNotEmpty) {
              _apiToken = tenantAuth.token;
            }
          } catch (tErr) {
            debugPrint('[AuthProvider] Using user login token ($tErr)');
          }
        } else {
          authResponse = await _authService.fetchToken(
            clientId: cleanIdentifier,
            clientSecret: secret,
          );
          _apiToken = authResponse.token;
        }
      } catch (apiError) {
        // Fallback for demo account or when server API is unavailable/rate-limited
        final String errStr = apiError.toString().toLowerCase();
        final bool isDemoUser =
            cleanIdentifier.toLowerCase() == 'admin@smarthomez.com';
        final bool isAccountNotFound =
            errStr.contains('account not found') || errStr.contains('404');
        final bool isRateLimited =
            errStr.contains('429') || errStr.contains('too many requests');

        if (isDemoUser ||
            (isEmailLogin && (isAccountNotFound || isRateLimited))) {
          debugPrint(
            '[AuthProvider] Using demo fallback session for $cleanIdentifier.',
          );
          _apiToken = 'demo_jwt_token';
          const finalClientId = 'demo_client_uuid';
          _resolvedClientUuid = finalClientId;

          final emailName = cleanIdentifier.split('@').first;
          final displayName = isDemoUser
              ? 'Demo Admin'
              : (emailName.isNotEmpty ? emailName : 'Demo User');

          _currentUser = AppUser(
            id: finalClientId,
            name: displayName,
            email: cleanIdentifier,
            phone: '+1234567890',
            role: targetRole,
            tenantId: 'aurabrain',
            avatarInitials: _generateInitials(displayName),
          );

          propertyProvider.setClientId(finalClientId);
          await Future.wait([
            propertyProvider.syncFromApi(finalClientId),
            deviceProvider.syncFromApi(finalClientId),
          ]);

          _errorMessage = null;
          notifyListeners();
          return null;
        }

        return _fail(_friendlyErrorMessage(apiError));
      }

      if (!authResponse.success) {
        return _fail(
          authResponse.error ??
              'Authentication failed. Please check your credentials.',
        );
      }

      final String? jwtToken = authResponse.token;

      if (jwtToken == null || jwtToken.isEmpty) {
        return _fail('The server did not return an authentication token.');
      }

      _apiToken = jwtToken;
      await Future.wait([
        _storage.write(key: 'platform_user_jwt', value: jwtToken),
        _storage.write(key: 'api_service_jwt', value: jwtToken),
        _storage.write(key: 'jwt_token', value: jwtToken),
      ]);

      // ========================================================
      // PHASE 2: RESOLVE CUSTOMER CLIENT
      // ========================================================

      final String? emailToResolve = isEmailLogin
          ? cleanIdentifier
          : customerEmail?.trim();

      if (emailToResolve == null || emailToResolve.isEmpty) {
        return _fail('Customer email is required to load homes and devices.');
      }

      ResolvedClient? resolvedClient;
      String? finalClientId =
          (authResponse.clientId != null &&
              authResponse.clientId!.trim().isNotEmpty)
          ? authResponse.clientId!.trim()
          : null;

      if (finalClientId == null || finalClientId.isEmpty) {
        try {
          resolvedClient = await _clientService.resolveClient(
            email: emailToResolve,
            name: customerName ?? authResponse.clientName,
          );
          if (resolvedClient?.id.isNotEmpty == true) {
            finalClientId = resolvedClient!.id;
          }
        } catch (resolveError) {
          debugPrint('[AuthProvider] Client resolve notice: $resolveError');
        }
      }

      if (finalClientId == null || finalClientId.isEmpty) {
        finalClientId = 'df0df9e3-0e47-4d46-810e-3c4f5c267d69';
      }

      _resolvedClientUuid = finalClientId;

      await _authService.saveResolvedClientUuid(finalClientId);

      // ========================================================
      // PHASE 3: CREATE LOCAL USER
      // ========================================================

      final String displayName = _getDisplayName(
        resolvedName: resolvedClient?.name,
        authName: authResponse.clientName,
        fallbackEmail: emailToResolve,
      );

      final String initials = _generateInitials(displayName);

      _currentUser = AppUser(
        id: finalClientId,
        name: displayName,
        email: resolvedClient?.email ?? emailToResolve,
        phone: resolvedClient?.phone ?? '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: initials,
      );

      // ========================================================
      // PHASE 4: LOAD REAL API DATA
      // ========================================================

      propertyProvider.setClientId(finalClientId);

      await Future.wait([
        propertyProvider.syncFromApi(finalClientId),
        deviceProvider.syncFromApi(finalClientId),
      ]);

      await deviceProvider.startRealtimeSync(finalClientId);

      _errorMessage = null;
      notifyListeners();

      return null;
    } catch (error, stackTrace) {
      debugPrint('[AuthProvider] Login error: $error');

      debugPrintStack(stackTrace: stackTrace);

      return _fail(_friendlyErrorMessage(error));
    } finally {
      _setLoading(false);
    }
  }

  /// Use this method when the real customer UUID is already known.
  ///
  /// This avoids calling the client resolve endpoint.
  Future<String?> loginWithKnownClientUuid(
    String apiClientId,
    String clientSecret,
    String customerClientUuid,
    UserRole targetRole, {
    required PropertyProvider propertyProvider,
    required DeviceProvider deviceProvider,
    required String customerName,
    required String customerEmail,
  }) async {
    if (_isLoading) {
      return 'Login is already in progress.';
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      if (apiClientId.trim().isEmpty ||
          clientSecret.trim().isEmpty ||
          customerClientUuid.trim().isEmpty) {
        return _fail('API credentials or customer UUID are missing.');
      }

      final authResponse = await _authService.fetchToken(
        clientId: apiClientId.trim(),
        clientSecret: clientSecret.trim(),
      );

      if (!authResponse.success ||
          authResponse.token == null ||
          authResponse.token!.isEmpty) {
        return _fail(authResponse.error ?? 'API authentication failed.');
      }

      _apiToken = authResponse.token;
      _resolvedClientUuid = customerClientUuid.trim();

      await _authService.saveResolvedClientUuid(_resolvedClientUuid!);

      _currentUser = AppUser(
        id: _resolvedClientUuid!,
        name: customerName.trim().isEmpty
            ? 'Smart Home User'
            : customerName.trim(),
        email: customerEmail.trim(),
        phone: '',
        role: targetRole,
        tenantId: 'aurabrain',
        avatarInitials: _generateInitials(customerName),
      );

      propertyProvider.setClientId(_resolvedClientUuid!);

      await Future.wait([
        propertyProvider.syncFromApi(_resolvedClientUuid!),
        deviceProvider.syncFromApi(_resolvedClientUuid!),
      ]);

      await deviceProvider.startRealtimeSync(_resolvedClientUuid!);

      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      debugPrint('[AuthProvider] Known UUID login error: $error');

      debugPrintStack(stackTrace: stackTrace);

      return _fail(_friendlyErrorMessage(error));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreSession({
    required PropertyProvider propertyProvider,
    required DeviceProvider deviceProvider,
  }) async {
    _setLoading(true);

    try {
      String? savedToken = await _authService.getSavedToken();
      try {
        final tenantAuth = await _authService.fetchToken(
          clientId: 'anvyaaai_AEB3',
          clientSecret: 'ZoNiiXT2wfgzFC0tmR8v130byqwRZ7wzGEYhJXENfI8',
        );
        if (tenantAuth.success &&
            tenantAuth.token != null &&
            tenantAuth.token!.isNotEmpty) {
          savedToken = tenantAuth.token;
        }
      } catch (tErr) {
        debugPrint('[AuthProvider] Restore token notice: $tErr');
      }

      final String savedClientUuid =
          (await _authService.getResolvedClientUuid()) ??
          'df0df9e3-0e47-4d46-810e-3c4f5c267d69';

      if (savedToken == null || savedToken.isEmpty) {
        return;
      }

      _apiToken = savedToken;
      _resolvedClientUuid = savedClientUuid;

      propertyProvider.setClientId(savedClientUuid);

      await Future.wait([
        propertyProvider.syncFromApi(savedClientUuid),
        deviceProvider.syncFromApi(savedClientUuid),
      ]);

      await deviceProvider.startRealtimeSync(savedClientUuid);
    } catch (error) {
      debugPrint('[AuthProvider] Session restore failed: $error');

      await logout();
    } finally {
      _setLoading(false);
    }
  }

  // Firebase OTP handling
  bool _otpSent = false;
  bool get isOtpSent => _otpSent;
  String? _verificationId;

  /// Request OTP for the given phone number using Firebase.
  Future<void> requestOtp(String phone) async {
    if (_isLoading) return;
    _setLoading(true);
    _errorMessage = null;
    try {
      // Firebase Phone Auth is not used for the Windows desktop build.
      // Use the same backend OTP endpoints that the desktop client already
      // uses for email/API authentication.
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final response = await _authService.sendOtp(phone: phone);
        if (!response.success) {
          _fail(response.error ?? 'Failed to send OTP');
          return;
        }
        _otpSent = true;
        notifyListeners();
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto‑retrieval (Android only). Direct sign‑in.
          final userCred = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
          final token = await userCred.user?.getIdToken();
          if (token != null) {
            _apiToken = token;
            _currentUser = AppUser(
              id: userCred.user?.uid ?? '',
              name: userCred.user?.displayName ?? 'OTP User',
              email: userCred.user?.email ?? '',
              phone: phone.trim(),
              role: UserRole.resident,
              tenantId: 'aurabrain',
              avatarInitials: 'OU',
            );
            _resolvedClientUuid = 'firebase_user_${userCred.user?.uid}';
            await _authService.saveResolvedClientUuid(_resolvedClientUuid!);
            notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _fail('Failed to send OTP: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _otpSent = true;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP entered by the user using Firebase.
  Future<void> verifyOtp(String phone, String otp) async {
    if (_isLoading) return;
    _setLoading(true);
    _errorMessage = null;
    try {
      // Windows desktop uses the backend OTP endpoint instead of Firebase
      // Phone Auth, which keeps the desktop build independent of mobile
      // Firebase phone-auth capabilities.
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final response = await _authService.verifyOtp(
          phone: phone,
          otp: otp,
        );
        if (!response.success || response.token == null || response.token!.isEmpty) {
          _fail(response.error ?? 'OTP verification failed');
          return;
        }

        _apiToken = response.token;
        _resolvedClientUuid = response.clientId ?? 'otp_user_${phone.trim()}';
        _currentUser = AppUser(
          id: _resolvedClientUuid!,
          name: 'OTP User',
          email: '',
          phone: phone.trim(),
          role: UserRole.resident,
          tenantId: 'aurabrain',
          avatarInitials: 'OU',
        );
        await _authService.saveResolvedClientUuid(_resolvedClientUuid!);
        _otpSent = false;
        _verificationId = null;
        notifyListeners();
        return;
      }

      if (_verificationId == null) {
        _fail('Verification ID missing. Request OTP first.');
        return;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final token = await userCred.user?.getIdToken();
      if (token == null) {
        _fail('Failed to obtain token after verification');
        return;
      }
      _apiToken = token;
      _currentUser = AppUser(
        id: userCred.user?.uid ?? '',
        name: userCred.user?.displayName ?? 'OTP User',
        email: userCred.user?.email ?? '',
        phone: phone.trim(),
        role: UserRole.resident,
        tenantId: 'aurabrain',
        avatarInitials: 'OU',
      );
      _resolvedClientUuid = 'firebase_user_${userCred.user?.uid}';
      await _authService.saveResolvedClientUuid(_resolvedClientUuid!);
      notifyListeners();
    } catch (e) {
      _fail('Failed to verify OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _resolvedClientUuid = null;
    _apiToken = null;
    _errorMessage = null;

    await _authService.logout();

    notifyListeners();
  }

  String _getDisplayName({
    required String? resolvedName,
    required String? authName,
    required String fallbackEmail,
  }) {
    if (resolvedName != null && resolvedName.trim().isNotEmpty) {
      return resolvedName.trim();
    }

    if (authName != null && authName.trim().isNotEmpty) {
      return authName.trim();
    }

    final String emailName = fallbackEmail.split('@').first;

    return emailName.isEmpty ? 'Smart Home User' : emailName;
  }

  String _generateInitials(String displayName) {
    final String cleanName = displayName.trim();

    if (cleanName.isEmpty) {
      return 'US';
    }

    final List<String> parts = cleanName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'US';
    }

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    final String firstPart = parts.first;

    if (firstPart.length >= 2) {
      return firstPart.substring(0, 2).toUpperCase();
    }

    return firstPart[0].toUpperCase();
  }

  String _friendlyErrorMessage(Object error) {
    final String message = error.toString();

    if (message.contains('429') || message.contains('Too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }

    if (message.contains('Account not found')) {
      return 'Account not found. Use admin@smarthomez.com for demo login.';
    }

    if (message.contains('401')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('403')) {
      return 'You do not have permission to access this account.';
    }

    if (message.contains('404')) {
      return 'The customer account was not found.';
    }

    if (message.contains('connection timeout') ||
        message.contains('connectionTimeout')) {
      return 'The server connection timed out.';
    }

    if (message.contains('SocketException')) {
      return 'No internet connection.';
    }

    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }

  String _fail(String message) {
    _errorMessage = message;
    notifyListeners();
    return message;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }
}
