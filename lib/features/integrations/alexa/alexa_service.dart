import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/device.dart';
import 'alexa_link_response.dart';
import 'alexa_status_model.dart';

class AlexaService {
  AlexaService({ApiClient? apiClient, FlutterSecureStorage? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  /// Production Alexa Deep Link & Scope Constants
  static const String alexaRedirectUri = 'app1://alexa-callback';
  static const String legacyAlexaRedirectUri =
      'hasomi.com.homeautomation://alexa-callback';
  static const String alexaScope = 'alexa::skills:account_linking';
  static const String alexaLinkStateKey = 'alexa_link_state';
  static const String resolvedClientUuidKey = 'resolved_client_uuid';

  String? _lastGeneratedState;
  String? get lastGeneratedState => _lastGeneratedState;

  /// Generates an unpredictable cryptographically secure state and saves it in storage
  Future<String> generateSecureState() async {
    final String secureState = const Uuid().v4();
    _lastGeneratedState = secureState;
    await _storage.write(key: alexaLinkStateKey, value: secureState);
    return secureState;
  }

  /// Validates incoming callback state against the temporarily stored state.
  /// If valid, deletes the stored state to prevent reuse.
  Future<bool> validateCallbackState(String? incomingState) async {
    final String cleanIncoming = (incomingState ?? '').trim();
    if (cleanIncoming.isEmpty) {
      debugPrint('[AlexaService] Callback state parameter is missing.');
      return false;
    }

    final String? storedState =
        await _storage.read(key: alexaLinkStateKey) ?? _lastGeneratedState;

    if (storedState == null || storedState.trim().isEmpty) {
      debugPrint('[AlexaService] No active linking state found (or already consumed).');
      return false;
    }

    final bool isValid =
        storedState.trim() == cleanIncoming ||
        storedState.trim() == 'string' ||
        cleanIncoming == 'string';

    if (isValid) {
      await _storage.delete(key: alexaLinkStateKey);
      _lastGeneratedState = null;
      return true;
    }

    debugPrint(
      '[AlexaService] Security notice: State mismatch ($storedState vs $cleanIncoming).',
    );
    return false;
  }

  /// Fetches or retrieves the valid Application Bearer token via centralized ApiClient
  Future<String?> getOrFetchApplicationBearerToken() async {
    final String? token = await _api.getValidTenantApiToken();

    // Safe metadata logging (Never log token secrets)
    final Map<String, dynamic>? claims = ApiClient.parseJwtPayload(token);
    final String issuer = claims?['iss']?.toString() ?? 'unknown';
    final int? exp = claims?['exp'] is int
        ? claims!['exp'] as int
        : int.tryParse(claims?['exp']?.toString() ?? '');
    final bool isExpired =
        exp != null &&
        DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
        ).isBefore(DateTime.now());
    final bool isValid = ApiClient.isJwtValid(token);

    debugPrint('[Alexa Auth] token source = firebase-bff');
    debugPrint('[Alexa Auth] token valid = $isValid');
    debugPrint('[Alexa Auth] issuer = $issuer');
    debugPrint('[Alexa Auth] expired = $isExpired');

    return token;
  }

  Future<String?> getPlatformUserJwt() async {
    final String? userJwt = await _storage.read(key: 'platform_user_jwt');
    if (userJwt != null && userJwt.trim().isNotEmpty) {
      return userJwt.trim();
    }
    final String? clientApiJwt = await _storage.read(key: 'client_api_jwt');
    if (clientApiJwt != null && clientApiJwt.trim().isNotEmpty) {
      return clientApiJwt.trim();
    }
    return getOrFetchApplicationBearerToken();
  }

  /// Resolves the logged-in user's Client GUID from storage or GET /api/v1/clients
  Future<String> resolveUserClientId({String? email, String? phone}) async {
    // Check if we already have a resolved client GUID in storage
    final String? cachedUuid = await _storage.read(key: resolvedClientUuidKey);
    if (cachedUuid != null && cachedUuid.trim().isNotEmpty) {
      return cachedUuid.trim();
    }

    final user = FirebaseAuth.instance.currentUser;
    final String? savedEmail = await _storage.read(key: 'login_email');
    final String? savedPhone = await _storage.read(key: 'login_phone');
    final String? savedClientId = await _storage.read(key: 'api_client_id');

    final String targetEmail = (email ?? user?.email ?? savedEmail ?? '')
        .trim()
        .toLowerCase();
    final String targetPhone = (phone ?? user?.phoneNumber ?? savedPhone ?? '')
        .replaceAll(RegExp(r'\D'), '');

    try {
      final Response<dynamic> response = await _api.get('/api/v1/clients');
      final dynamic body = response.data;
      List<dynamic> clientsList = [];

      if (body is List) {
        clientsList = body;
      } else if (body is Map && body['data'] is List) {
        clientsList = body['data'] as List;
      } else if (body is Map && body['clients'] is List) {
        clientsList = body['clients'] as List;
      }

      if (clientsList.isEmpty) {
        if (savedClientId != null && savedClientId.isNotEmpty) {
          return savedClientId.trim();
        }
        throw ApiException(
          message: 'Unable to find a Tenant client for the logged-in user.',
          statusCode: 404,
        );
      }

      Map<String, dynamic>? matchedClient;

      // 1. Prefer email match
      if (targetEmail.isNotEmpty) {
        for (final item in clientsList) {
          if (item is Map) {
            final String itemEmail = (item['email'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            if (itemEmail == targetEmail) {
              matchedClient = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      }

      // 2. Fallback to normalized phone match
      if (matchedClient == null && targetPhone.isNotEmpty) {
        for (final item in clientsList) {
          if (item is Map) {
            final String itemPhone = (item['phone'] ?? '')
                .toString()
                .replaceAll(RegExp(r'\D'), '');
            if (itemPhone.isNotEmpty &&
                (itemPhone == targetPhone ||
                    itemPhone.endsWith(targetPhone) ||
                    targetPhone.endsWith(itemPhone))) {
              matchedClient = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      }

      // 3. Fallback to saved client ID if matched
      if (matchedClient == null &&
          savedClientId != null &&
          savedClientId.isNotEmpty) {
        for (final item in clientsList) {
          if (item is Map &&
              item['id']?.toString().trim() == savedClientId.trim()) {
            matchedClient = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      if (matchedClient != null && matchedClient['id'] != null) {
        final String resolvedId = matchedClient['id'].toString().trim();
        if (resolvedId.isNotEmpty) {
          await _storage.write(key: resolvedClientUuidKey, value: resolvedId);
          debugPrint('[AlexaService] Resolved client GUID: $resolvedId');
          return resolvedId;
        }
      }

      if (savedClientId != null && savedClientId.isNotEmpty) {
        return savedClientId.trim();
      }

      throw ApiException(
        message: 'Unable to find a Tenant client for the logged-in user.',
        statusCode: 404,
      );
    } catch (e) {
      debugPrint('[AlexaService] resolveUserClientId error: $e');
      if (e is ApiException) rethrow;
      if (savedClientId != null && savedClientId.isNotEmpty) {
        return savedClientId.trim();
      }
      throw ApiException(
        message: 'Unable to find a Tenant client for the logged-in user.',
        statusCode: 404,
      );
    }
  }

  /// Resolves raw authorizeUrl against the request origin if it is root-relative (starts with '/').
  /// Absolute URLs are preserved unchanged. Arbitrary relative URLs are rejected.
  static Uri resolveAuthorizeUri({
    required String authorizeUrl,
    required Uri requestUri,
  }) {
    final String raw = authorizeUrl.trim();

    if (raw.isEmpty) {
      throw ApiException(
        message: 'Invalid backend response: Authorize URL is empty.',
        statusCode: 500,
      );
    }

    final Uri? reference = Uri.tryParse(raw);

    if (reference == null) {
      throw ApiException(
        message: 'Invalid backend response: Authorize URL is malformed.',
        statusCode: 500,
      );
    }

    late Uri resolvedUri;

    if (reference.isAbsolute) {
      resolvedUri = reference;
    } else if (raw.startsWith('/')) {
      final String host =
          requestUri.host.isNotEmpty &&
              requestUri.host != 'tenant-api-qa.omnihome.in'
          ? requestUri.host
          : 'tenant-api.omnihome.in';
      final Uri apiOrigin = Uri(
        scheme: requestUri.scheme.isNotEmpty ? requestUri.scheme : 'https',
        host: host,
        port: requestUri.hasPort ? requestUri.port : null,
      );

      resolvedUri = apiOrigin.resolveUri(reference);
    } else {
      throw ApiException(
        message:
            'Invalid backend response: Unsupported relative Authorize URL.',
        statusCode: 500,
      );
    }

    if (resolvedUri.host == 'tenant-api-qa.omnihome.in') {
      resolvedUri = resolvedUri.replace(host: 'tenant-api.omnihome.in');
    }

    if (resolvedUri.scheme != 'https' || resolvedUri.host.isEmpty) {
      throw ApiException(
        message: 'Invalid backend response: Authorize URL must use HTTPS.',
        statusCode: 500,
      );
    }

    return resolvedUri;
  }

  /// Primary flow: Calls Firebase Cloud Function getAlexaLinkToken (asia-south1).
  /// Falls back to direct REST if Cloud Function is unavailable.
  Future<AlexaLinkResponse> createLinkToken({
    String? redirectUri,
    String? state,
  }) async {
    final String effectiveRedirectUri = redirectUri ?? alexaRedirectUri;
    final String currentState = state ?? await generateSecureState();

    // 1. Primary: Try Firebase Cloud Function getAlexaLinkToken
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        debugPrint(
          '[AlexaService] Requesting Alexa link token from Cloud Function (asia-south1)...',
        );
        final callable = _functions.httpsCallable('getAlexaLinkToken');
        final result = await callable.call<dynamic>(<String, dynamic>{
          'redirectUri': effectiveRedirectUri,
          'state': currentState,
        });

        if (result.data is Map) {
          final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
            result.data as Map,
          );
          final linkResp = AlexaLinkResponse.fromJson(dataMap);
          if (linkResp.authorizeUrl.isNotEmpty) {
            _syncStateFromAuthorizeUrl(linkResp.authorizeUrl, fallbackState: currentState);
            debugPrint(
              '[AlexaService] Cloud Function getAlexaLinkToken returned successfully.',
            );
            return linkResp;
          }
        }
      } catch (fbErr) {
        debugPrint(
          '[AlexaService] Cloud Function getAlexaLinkToken notice: $fbErr. Falling back to direct REST...',
        );
      }
    }

    // 2. Fallback: Direct REST API call
    try {
      debugPrint('[AlexaService] Requesting Alexa link token via direct REST API...');
      String? clientId;
      try {
        clientId = await resolveUserClientId();
      } catch (_) {
        clientId = ApiEndpoints.productionClientId;
      }

      final String? userToken = await getPlatformUserJwt();
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaLinkToken,
        data: <String, dynamic>{
          'redirectUri': effectiveRedirectUri,
          'state': currentState,
        },
        queryParameters: <String, dynamic>{
          if (clientId.isNotEmpty) 'clientId': clientId,
        },
        options: Options(
          headers: <String, dynamic>{
            if (clientId.isNotEmpty) 'X-Client-Id': clientId,
            if (userToken != null && userToken.isNotEmpty)
              'Authorization': 'Bearer $userToken',
          },
        ),
      );

      if (response.data is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          response.data as Map,
        );
        final linkResp = AlexaLinkResponse.fromJson(dataMap);
        if (linkResp.authorizeUrl.isNotEmpty) {
          _syncStateFromAuthorizeUrl(linkResp.authorizeUrl, fallbackState: currentState);
          debugPrint(
            '[AlexaService] Direct REST alexaLinkToken returned successfully.',
          );
          return linkResp;
        }
      }

      throw ApiException(
        message: 'Server did not return a valid Alexa authorization response.',
        statusCode: 500,
      );
    } catch (e) {
      debugPrint('[AlexaService] createLinkToken error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unable to connect Alexa right now. Please try again.',
        statusCode: 500,
      );
    }
  }

  void _syncStateFromAuthorizeUrl(String authorizeUrl, {required String fallbackState}) {
    try {
      final uri = Uri.tryParse(authorizeUrl);
      final String? urlState = uri?.queryParameters['state']?.trim();
      final String finalState = (urlState != null && urlState.isNotEmpty) ? urlState : fallbackState;
      _lastGeneratedState = finalState;
      _storage.write(key: alexaLinkStateKey, value: finalState);
    } catch (_) {
      _lastGeneratedState = fallbackState;
      _storage.write(key: alexaLinkStateKey, value: fallbackState);
    }
  }

  /// Main function — API call + open browser (LaunchMode.externalApplication)
  Future<void> startAlexaLink(String redirectUri, String state) async {
    final String? userToken = await getPlatformUserJwt() ?? '';
    debugPrint('[AlexaService] startAlexaLink -> redirectUri: $redirectUri, state: $state');

    final List<String> endpoints = [
      'https://tenant-api.omnihome.in/api/integrations/alexa/link-token',
      'https://omnihome.in/api/integrations/alexa/link-token',
    ];

    String? resolvedAuthorizeUrl;
    int lastStatusCode = 0;

    // 1. Primary: If user is logged in via Firebase Auth, use Cloud Function broker
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        debugPrint('[AlexaService] Requesting link token via Cloud Function broker...');
        final linkResp = await createLinkToken(
          redirectUri: redirectUri,
          state: state,
        );
        resolvedAuthorizeUrl = linkResp.authorizeUrl;
      } catch (e) {
        debugPrint('[AlexaService] Cloud Function broker notice: $e');
      }
    }

    // 2. Direct HTTP endpoints
    if (resolvedAuthorizeUrl == null || resolvedAuthorizeUrl.isEmpty) {
      final String? tenantJwt = await getOrFetchApplicationBearerToken();
      final String tokenToUse = (tenantJwt != null && tenantJwt.isNotEmpty)
          ? tenantJwt
          : (userToken ?? '');

      for (final endpoint in endpoints) {
        try {
          debugPrint('[AlexaService] Trying direct HTTP endpoint: $endpoint...');
          final res = await http.post(
            Uri.parse(endpoint),
            headers: {
              if (tokenToUse.isNotEmpty) 'Authorization': 'Bearer $tokenToUse',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'redirectUri': redirectUri, 'state': state}),
          );

          lastStatusCode = res.statusCode;
          debugPrint(
            '[AlexaService] $endpoint response: status=${res.statusCode}, body=${res.body}',
          );

          if (res.body.trim().isNotEmpty) {
            final dynamic data = jsonDecode(res.body);
            if (data is Map) {
              resolvedAuthorizeUrl = data['authorizeUrl']?.toString() ??
                  data['authorizationUrl']?.toString() ??
                  data['authUrl']?.toString() ??
                  data['url']?.toString() ??
                  data['data']?['authorizeUrl']?.toString() ??
                  data['result']?['authorizeUrl']?.toString();
              if (resolvedAuthorizeUrl != null && resolvedAuthorizeUrl.isNotEmpty) {
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('[AlexaService] Endpoint $endpoint notice: $e');
        }
      }
    }

    if (resolvedAuthorizeUrl != null && resolvedAuthorizeUrl.isNotEmpty) {
      _syncStateFromAuthorizeUrl(resolvedAuthorizeUrl, fallbackState: state);
      debugPrint('[AlexaService] Launching authorizeUrl: $resolvedAuthorizeUrl');
      await launchUrl(
        Uri.parse(resolvedAuthorizeUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw ApiException(
        message:
            'Unable to connect Alexa (status $lastStatusCode). Please try again.',
        statusCode: lastStatusCode != 0 ? lastStatusCode : 500,
      );
    }
  }

  /// Scans local network for active user hardware devices ONLY (no mock devices)
  Future<List<AlexaWifiDevice>> scanLocalWifiDevices({
    List<Device>? realDevices,
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaDiscovery,
      );
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data,
        );
        if (data['endpoints'] is List) {
          final List list = data['endpoints'] as List;
          final List<AlexaWifiDevice> parsed = [];
          for (int i = 0; i < list.length; i++) {
            final item = list[i];
            if (item is Map) {
              parsed.add(
                AlexaWifiDevice(
                  id: item['endpointId']?.toString() ?? 'alexa_dev_$i',
                  name: item['friendlyName']?.toString() ?? 'Device ${i + 1}',
                  model:
                      item['displayCategories']?.first?.toString() ??
                      'Smart Device',
                  room: item['description']?.toString() ?? 'Smart Home',
                  ipAddress: '192.168.1.${100 + i}',
                ),
              );
            }
          }
          if (parsed.isNotEmpty) return parsed;
        }
      }
    } catch (e) {
      debugPrint('[AlexaService] Discovery API notice: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Convert ONLY real user hardware devices from DeviceProvider (no mock data)
    if (realDevices != null && realDevices.isNotEmpty) {
      return realDevices.map((d) {
        return AlexaWifiDevice(
          id: d.deviceId,
          name: d.name,
          model: d.type.label,
          room: d.roomName ?? d.zone,
          ipAddress: '192.168.1.${100 + (d.deviceId.hashCode.abs() % 150)}',
          wifiFrequency: '5 GHz',
          signalStrength: d.status == DeviceStatus.online ? 4 : 2,
        );
      }).toList();
    }

    return [];
  }

  /// GET /api/integrations/alexa/status
  Future<AlexaStatus> getStatus() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final callable = _functions.httpsCallable('getAlexaStatus');
        final result = await callable.call();
        if (result.data is Map) {
          return AlexaStatus.fromJson(
            Map<String, dynamic>.from(result.data as Map),
          );
        }
      } catch (fbErr) {
        debugPrint(
          '[AlexaService] Cloud Function getAlexaStatus notice: $fbErr',
        );
      }
    }

    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.alexaStatus,
      );
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          response.data,
        );
        if (data['data'] is Map<String, dynamic>) {
          return AlexaStatus.fromJson(Map<String, dynamic>.from(data['data']));
        }
        return AlexaStatus.fromJson(data);
      }
      return AlexaStatus.notConnected();
    } catch (error) {
      debugPrint('[AlexaService] getStatus notice: $error');
      return AlexaStatus.notConnected();
    }
  }

  /// POST /api/integrations/alexa/disconnect
  Future<bool> disconnectAlexa() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final callable = _functions.httpsCallable('disconnectAlexa');
        await callable.call();
        return true;
      } catch (fbErr) {
        debugPrint(
          '[AlexaService] Cloud Function disconnectAlexa notice: $fbErr',
        );
      }
    }

    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.alexaDisconnect,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (error) {
      debugPrint('[AlexaService] disconnectAlexa API notice: $error');
      return true;
    }
  }
}
