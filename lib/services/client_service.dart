import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/resolved_client.dart';

class ClientService {
  ClientService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Resolves an existing customer, or creates one when supported by the API.
  /// At least one of [email] or [phone] should be provided.
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
      if (responseBody is! Map) {
        return null;
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(responseBody);

      if (body['success'] != true || body['data'] == null) {
        debugPrint(
          '[ClientService] Resolve failed: ${body['error'] ?? 'Unknown error'}',
        );
        return null;
      }

      final dynamic resolvedData = body['data'];
      if (resolvedData is! Map) {
        return null;
      }

      return ResolvedClient.fromJson(Map<String, dynamic>.from(resolvedData));
    } catch (error) {
      debugPrint('[ClientService] Resolve client error: $error');
      rethrow;
    }
  }

  /// Returns all clients available to the authenticated API account.
  Future<List<ResolvedClient>> getClients() async {
    try {
      final Response<dynamic> response = await _api.get(ApiEndpoints.clients);

      final dynamic responseBody = response.data;
      if (responseBody is! Map) {
        return const <ResolvedClient>[];
      }

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
      rethrow;
    }
  }
}
