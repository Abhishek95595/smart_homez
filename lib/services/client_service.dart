import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/resolved_client.dart';

class ClientService {
  ClientService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Resolves an existing customer, or creates one when supported by the API.
  Future<ResolvedClient?> resolveClient({
    String? email,
    String? phone,
    String? name,
  }) async {
    final String? cleanEmail = email?.trim();
    final String? cleanPhone = phone?.trim();
    final String? cleanName = name?.trim();

    if ((cleanEmail == null || cleanEmail.isEmpty) &&
        (cleanPhone == null || cleanPhone.isEmpty)) {
      throw ArgumentError('Email or phone is required to resolve a client.');
    }

    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.resolveClient,
        data: <String, dynamic>{
          if (cleanEmail != null && cleanEmail.isNotEmpty) 'email': cleanEmail,
          if (cleanPhone != null && cleanPhone.isNotEmpty) 'phone': cleanPhone,
          if (cleanName != null && cleanName.isNotEmpty) 'name': cleanName,
        },
      );

      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      if (body['success'] != true || body['data'] == null) {
        debugPrint(
          '[ClientService] Resolve failed: ${body['error'] ?? 'Unknown error'}',
        );
        return null;
      }

      final dynamic resolvedData = body['data'];
      if (resolvedData is! Map) return null;

      return ResolvedClient.fromJson(Map<String, dynamic>.from(resolvedData));
    } catch (error) {
      debugPrint('[ClientService] Resolve client error: $error');
      rethrow;
    }
  }

  /// Create a client via OTP verification.
  Future<bool> createClient({
    required String name,
    required String contact, // Email or Phone
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.createClient,
        data: {'name': name.trim(), 'contact': contact.trim()},
      );
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data,
      );
      return body['success'] == true;
    } catch (error) {
      debugPrint('[ClientService] Create client error: $error');
      return false;
    }
  }

  /// Verify OTP for pending client creation.
  Future<bool> verifyClientOtp({
    required String contact,
    required String otp,
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.verifyClient,
        data: {'contact': contact.trim(), 'otp': otp.trim()},
      );
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data,
      );
      return body['success'] == true;
    } catch (error) {
      debugPrint('[ClientService] Verify client OTP error: $error');
      return false;
    }
  }

  /// Initiate password reset for client.
  Future<bool> resetPassword(String clientId) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.resetPassword(clientId),
      );
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data,
      );
      return body['success'] == true;
    } catch (error) {
      debugPrint('[ClientService] Reset password error: $error');
      return false;
    }
  }

  /// Verify password reset OTP.
  Future<bool> verifyResetPassword({
    required String clientId,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.verifyResetPassword(clientId),
        data: {'otp': otp.trim(), 'newPassword': newPassword},
      );
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data,
      );
      return body['success'] == true;
    } catch (error) {
      debugPrint('[ClientService] Verify reset password error: $error');
      return false;
    }
  }

  /// Trigger vendor device synchronization for a client.
  Future<bool> syncClientDevices(String clientId) async {
    try {
      final Response<dynamic> response = await _api.post(
        ApiEndpoints.syncClientDevices(clientId),
      );
      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data,
      );
      return body['success'] == true;
    } catch (error) {
      debugPrint('[ClientService] Sync client devices error: $error');
      return false;
    }
  }

  /// Returns all clients available to the authenticated API account.
  Future<List<ResolvedClient>> getClients() async {
    try {
      final Response<dynamic> response = await _api.get(ApiEndpoints.clients);
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return const <ResolvedClient>[];

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! List) {
        return const <ResolvedClient>[];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => ResolvedClient.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (error) {
      debugPrint('[ClientService] Get clients error: $error');
      return const <ResolvedClient>[];
    }
  }

  /// Get specific client details by clientId.
  Future<ResolvedClient?> getClient(String clientId) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.client(clientId),
      );
      final dynamic responseBody = response.data;
      if (responseBody is! Map) return null;

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);
      final dynamic data = body['data'];

      if (body['success'] != true || data is! Map) return null;

      return ResolvedClient.fromJson(Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('[ClientService] Get client error: $error');
      return null;
    }
  }
}
