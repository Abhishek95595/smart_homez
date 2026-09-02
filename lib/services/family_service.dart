import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/family_member_model.dart';

class FamilyService {
  FamilyService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /api/v1/clients/{clientId}/family/members
  /// Fetches authoritative family roster for a client: role, join status, contact details and last presence.
  Future<List<FamilyMember>> getFamilyMembers(String clientId) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientFamilyMembers(clientId),
      );

      final dynamic responseBody = response.data;
      if (responseBody is List) {
        return responseBody
            .whereType<Map>()
            .map(
              (item) => FamilyMember.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (responseBody is Map) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          responseBody,
        );
        final dynamic data = body['data'] ?? body['members'] ?? body['items'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map(
                (item) =>
                    FamilyMember.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
      }

      return const <FamilyMember>[];
    } catch (error) {
      debugPrint('[FamilyService] getFamilyMembers error: $error');
      rethrow;
    }
  }

  /// POST /api/v1/clients/{clientId}/family/invite
  /// Invite a family member by email (and optional phone/name/role) for the given client.
  Future<Map<String, dynamic>> inviteFamilyMember({
    required String clientId,
    String? email,
    String? phone,
    String? name,
    String? role,
    String? accessLevel,
  }) async {
    try {
      final finalRole = (role ?? accessLevel ?? 'member').toLowerCase();
      final Map<String, dynamic> payload = {
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'role': finalRole,
        'accessLevel': finalRole,
      };

      final Response<dynamic> response = await _api.post(
        ApiEndpoints.clientFamilyInvite(clientId),
        data: payload,
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'success': true};
    } catch (error) {
      debugPrint('[FamilyService] inviteFamilyMember error: $error');
      rethrow;
    }
  }

  /// PUT /api/v1/clients/{clientId}/family/members/{id}/role
  /// Update a family member's role (Admin vs Member).
  Future<bool> updateMemberRole({
    required String clientId,
    required String memberId,
    required String role,
  }) async {
    try {
      final formattedRole = role.toLowerCase();
      final Response<dynamic> response = await _api.put(
        ApiEndpoints.clientFamilyMemberRole(clientId, memberId),
        data: {'role': formattedRole},
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (error) {
      debugPrint('[FamilyService] updateMemberRole error: $error');
      return false;
    }
  }

  /// DELETE /api/v1/clients/{clientId}/family/members/{id}
  /// Revoke/remove a family member (deactivates login, drops invite token + device permissions).
  Future<bool> removeFamilyMember({
    required String clientId,
    required String memberId,
  }) async {
    try {
      final Response<dynamic> response = await _api.delete(
        ApiEndpoints.clientFamilyMember(clientId, memberId),
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (error) {
      debugPrint('[FamilyService] removeFamilyMember error: $error');
      return false;
    }
  }

  /// POST /api/v1/clients/{clientId}/family/invites/resend
  /// Resend a pending family invitation (rotates token, extends 30 days).
  Future<bool> resendInvite({
    required String clientId,
    required String memberId,
    String? email,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'memberId': memberId,
        'id': memberId,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      };

      final Response<dynamic> response = await _api.post(
        ApiEndpoints.clientFamilyResendInvite(clientId),
        data: payload,
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (error) {
      debugPrint('[FamilyService] resendInvite error: $error');
      return false;
    }
  }

  /// GET /api/v1/clients/{clientId}/family/members/{id}/join-link
  /// Return the single-use join link for a pending (not yet joined) family member.
  Future<String?> getJoinLink({
    required String clientId,
    required String memberId,
  }) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientFamilyJoinLink(clientId, memberId),
      );

      if (response.data is String) return response.data as String;
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        if (data['data'] is Map) {
          final nested = Map<String, dynamic>.from(data['data'] as Map);
          return nested['joinLink']?.toString() ??
              nested['link']?.toString() ??
              nested['url']?.toString();
        }
        return data['joinLink']?.toString() ??
            data['link']?.toString() ??
            data['url']?.toString();
      }
      return null;
    } catch (error) {
      debugPrint('[FamilyService] getJoinLink error: $error');
      return null;
    }
  }

  /// GET /api/v1/clients/{clientId}/family/members/{id}/device-permissions
  /// Retrieve the per-device permission matrix for a family member.
  Future<List<FamilyDevicePermissionEntry>> getDevicePermissions({
    required String clientId,
    required String memberId,
  }) async {
    try {
      final Response<dynamic> response = await _api.get(
        ApiEndpoints.clientFamilyDevicePermissions(clientId, memberId),
      );

      final dynamic responseBody = response.data;
      if (responseBody is List) {
        return responseBody
            .whereType<Map>()
            .map(
              (item) => FamilyDevicePermissionEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      if (responseBody is Map) {
        final Map<String, dynamic> body = Map<String, dynamic>.from(
          responseBody,
        );
        final dynamic data =
            body['data'] ?? body['permissions'] ?? body['items'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map(
                (item) => FamilyDevicePermissionEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      return const <FamilyDevicePermissionEntry>[];
    } catch (error) {
      debugPrint('[FamilyService] getDevicePermissions error: $error');
      return const <FamilyDevicePermissionEntry>[];
    }
  }

  /// PUT /api/v1/clients/{clientId}/family/members/{id}/device-permissions
  /// Batch-update the per-device permission flags for a family member.
  Future<bool> updateDevicePermissions({
    required String clientId,
    required String memberId,
    required List<FamilyDevicePermissionEntry> permissions,
  }) async {
    try {
      final payload = {
        'permissions': permissions.map((p) => p.toJson()).toList(),
      };

      final Response<dynamic> response = await _api.put(
        ApiEndpoints.clientFamilyDevicePermissions(clientId, memberId),
        data: payload,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
      return false;
    } catch (error) {
      debugPrint('[FamilyService] updateDevicePermissions error: $error');
      return false;
    }
  }
}
