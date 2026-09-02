import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/device.dart';
import '../models/family_member_model.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

class FamilyProvider extends ChangeNotifier {
  FamilyProvider({
    FamilyService? familyService,
    AuthService? authService,
    FlutterSecureStorage? storage,
  }) : _familyService = familyService ?? FamilyService(),
       _authService = authService ?? AuthService(),
       _storage = storage ?? const FlutterSecureStorage();

  final FamilyService _familyService;
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  List<FamilyMember> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _cachedClientId;

  List<FamilyMember> get members => List.unmodifiable(_members);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get activeMembersCount => _members.where((m) => m.isActive).length;
  int get pendingInvitesCount => _members.where((m) => m.isPending).length;

  Future<String?> _resolveClientId() async {
    if (_cachedClientId != null && _cachedClientId!.isNotEmpty) {
      return _cachedClientId;
    }
    String? id = await _authService.getResolvedClientUuid();
    id ??= await _storage.read(key: 'api_client_id');
    id ??= await _storage.read(key: 'resolved_client_uuid');
    id ??= '03d6aaff-f21b-41fc-902f-8184dacd0861'; // Match global app default user GUID
    _cachedClientId = id;
    return id;
  }

  /// Sets client ID explicitly (e.g. from AuthProvider).
  void setClientId(String? clientId) {
    if (clientId != null && clientId.isNotEmpty) {
      _cachedClientId = clientId;
    }
  }

  /// GET /api/v1/clients/{clientId}/family/members
  /// Fetches family members for the current client.
  Future<void> fetchMembers({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final clientId = await _resolveClientId();
      if (clientId == null || clientId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final fetched = await _familyService.getFamilyMembers(clientId);
      _members = fetched;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[FamilyProvider] fetchMembers error: $e');
      _errorMessage = 'Could not sync remote family members.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/v1/clients/{clientId}/family/invite
  /// Invites a family member by email or phone and configures device permissions.
  Future<FamilyMember?> inviteMember({
    String? email,
    String? phone,
    String? name,
    String role = 'member',
    bool grantAllDevices = true,
    List<String>? specificDeviceIds,
    List<Device>? availableDevices,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? cleanEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : null;
      final String? cleanPhone = (phone != null && phone.trim().isNotEmpty)
          ? phone.trim()
          : null;
      final clientId = await _resolveClientId();

      String memberId = 'inv_${DateTime.now().millisecondsSinceEpoch}';
      Map<String, dynamic>? inviteResponse;

      if (clientId != null && clientId.isNotEmpty) {
        try {
          inviteResponse = await _familyService.inviteFamilyMember(
            clientId: clientId,
            email: cleanEmail,
            phone: cleanPhone,
            name: name,
            role: role,
          );

          if (inviteResponse['id'] != null) {
            memberId = inviteResponse['id'].toString();
          } else if (inviteResponse['memberId'] != null) {
            memberId = inviteResponse['memberId'].toString();
          } else if (inviteResponse['data'] is Map &&
              (inviteResponse['data']['id'] != null ||
                  inviteResponse['data']['memberId'] != null)) {
            memberId =
                (inviteResponse['data']['id'] ??
                        inviteResponse['data']['memberId'])
                    .toString();
          }
        } catch (apiErr) {
          debugPrint('[FamilyProvider] Remote invite API error: $apiErr');
        }
      }

      // Build permissions list
      List<FamilyDevicePermissionEntry> permissions = [];
      if (grantAllDevices &&
          availableDevices != null &&
          availableDevices.isNotEmpty) {
        permissions = availableDevices
            .map(
              (dev) => FamilyDevicePermissionEntry(
                deviceId: dev.deviceId,
                deviceName: dev.name,
                canView: true,
                canControl: true,
              ),
            )
            .toList();
      } else if (specificDeviceIds != null && specificDeviceIds.isNotEmpty) {
        permissions = specificDeviceIds
            .map(
              (devId) => FamilyDevicePermissionEntry(
                deviceId: devId,
                canView: true,
                canControl: true,
              ),
            )
            .toList();
      }

      // If clientId and memberId are valid, sync device permissions to backend
      if (clientId != null && clientId.isNotEmpty && permissions.isNotEmpty) {
        try {
          await _familyService.updateDevicePermissions(
            clientId: clientId,
            memberId: memberId,
            permissions: permissions,
          );
        } catch (permErr) {
          debugPrint('[FamilyProvider] Permission sync error: $permErr');
        }
      }

      final newMember = FamilyMember(
        id: memberId,
        name: name?.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        role: role,
        status: 'pending',
        createdAt: DateTime.now(),
        permissions: permissions,
        allDevicesGranted: grantAllDevices,
      );

      _members = [
        newMember,
        ..._members.where(
          (m) =>
              (cleanEmail == null || m.email != cleanEmail) &&
              (cleanPhone == null || m.phone != cleanPhone),
        ),
      ];
      _isLoading = false;
      notifyListeners();
      return newMember;
    } catch (e) {
      debugPrint('[FamilyProvider] inviteMember error: $e');
      _errorMessage = 'Failed to invite family member: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Convenience wrapper for inviting by phone
  Future<FamilyMember?> inviteMemberByPhone({
    required String phone,
    String? name,
    String? email,
    String accessLevel = 'member',
    bool grantAllDevices = true,
    List<String>? specificDeviceIds,
    List<Device>? availableDevices,
  }) => inviteMember(
    phone: phone,
    email: email,
    name: name,
    role: accessLevel,
    grantAllDevices: grantAllDevices,
    specificDeviceIds: specificDeviceIds,
    availableDevices: availableDevices,
  );

  /// Grants access of all devices to an existing family member.
  Future<bool> grantAllDevicesAccess({
    required String memberId,
    required List<Device> availableDevices,
  }) async {
    try {
      final clientId = await _resolveClientId();
      final permissions = availableDevices
          .map(
            (d) => FamilyDevicePermissionEntry(
              deviceId: d.deviceId,
              deviceName: d.name,
              canView: true,
              canControl: true,
            ),
          )
          .toList();

      if (clientId != null && clientId.isNotEmpty) {
        await _familyService.updateDevicePermissions(
          clientId: clientId,
          memberId: memberId,
          permissions: permissions,
        );
      }

      final idx = _members.indexWhere((m) => m.id == memberId);
      if (idx != -1) {
        _members[idx] = _members[idx].copyWith(
          permissions: permissions,
          allDevicesGranted: true,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[FamilyProvider] grantAllDevicesAccess error: $e');
      return false;
    }
  }

  /// GET /api/v1/clients/{clientId}/family/members/{id}/device-permissions
  /// Retrieves per-device permissions for a family member from API.
  Future<List<FamilyDevicePermissionEntry>> fetchMemberDevicePermissions(
    String memberId,
  ) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        final perms = await _familyService.getDevicePermissions(
          clientId: clientId,
          memberId: memberId,
        );
        if (perms.isNotEmpty) {
          final idx = _members.indexWhere((m) => m.id == memberId);
          if (idx != -1) {
            _members[idx] = _members[idx].copyWith(permissions: perms);
            notifyListeners();
          }
          return perms;
        }
      }
    } catch (e) {
      debugPrint('[FamilyProvider] fetchMemberDevicePermissions error: $e');
    }
    final idx = _members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      return _members[idx].permissions;
    }
    return const [];
  }

  /// PUT /api/v1/clients/{clientId}/family/members/{id}/device-permissions
  /// Updates specific per-device permission list for a family member.
  Future<bool> updateMemberDevicePermissions({
    required String memberId,
    required List<FamilyDevicePermissionEntry> permissions,
    required int totalAvailableDevicesCount,
  }) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        await _familyService.updateDevicePermissions(
          clientId: clientId,
          memberId: memberId,
          permissions: permissions,
        );
      }

      final activePerms = permissions
          .where((p) => p.canView || p.canControl)
          .toList();
      final bool allGranted =
          totalAvailableDevicesCount > 0 &&
          activePerms.length >= totalAvailableDevicesCount;

      final idx = _members.indexWhere((m) => m.id == memberId);
      if (idx != -1) {
        _members[idx] = _members[idx].copyWith(
          permissions: permissions,
          allDevicesGranted: allGranted,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[FamilyProvider] updateMemberDevicePermissions error: $e');
      return false;
    }
  }

  /// POST /api/v1/clients/{clientId}/family/invites/resend
  /// Resends invitation SMS/Email / rotates token and extends validity.
  Future<bool> resendInvite(
    String memberId, {
    String? email,
    String? phone,
  }) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        final member = _members.firstWhere(
          (m) => m.id == memberId,
          orElse: () => FamilyMember(id: memberId, email: email, phone: phone),
        );
        return await _familyService.resendInvite(
          clientId: clientId,
          memberId: memberId,
          email: email ?? member.email,
          phone: phone ?? member.phone,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[FamilyProvider] resendInvite error: $e');
      return false;
    }
  }

  /// GET /api/v1/clients/{clientId}/family/members/{id}/join-link
  /// Retrieves single-use join link for a pending member.
  Future<String?> getJoinLink(
    String memberId, {
    String? fallbackPhone,
    String? fallbackEmail,
  }) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        final link = await _familyService.getJoinLink(
          clientId: clientId,
          memberId: memberId,
        );
        if (link != null && link.isNotEmpty) return link;
      }

      final member = _members.firstWhere(
        (m) => m.id == memberId,
        orElse: () => FamilyMember(
          id: memberId,
          phone: fallbackPhone,
          email: fallbackEmail,
        ),
      );
      final queryParam = member.email?.isNotEmpty == true
          ? 'email=${Uri.encodeComponent(member.email!)}'
          : 'phone=${Uri.encodeComponent((member.phone ?? '').replaceAll(RegExp(r'[^\d+]'), ''))}';
      return 'https://tenant-api-qa.omnihome.in/invite?$queryParam';
    } catch (e) {
      debugPrint('[FamilyProvider] getJoinLink error: $e');
      return null;
    }
  }

  /// PUT /api/v1/clients/{clientId}/family/members/{id}/role
  /// Updates family member role (Admin vs Member).
  Future<bool> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        final ok = await _familyService.updateMemberRole(
          clientId: clientId,
          memberId: memberId,
          role: role,
        );
        if (!ok) return false;
      }
      final idx = _members.indexWhere((m) => m.id == memberId);
      if (idx != -1) {
        _members[idx] = _members[idx].copyWith(role: role);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[FamilyProvider] updateMemberRole error: $e');
      return false;
    }
  }

  /// DELETE /api/v1/clients/{clientId}/family/members/{id}
  /// Revokes or deletes a family member.
  Future<bool> removeMember(String memberId) async {
    try {
      final clientId = await _resolveClientId();
      if (clientId != null && clientId.isNotEmpty) {
        final ok = await _familyService.removeFamilyMember(
          clientId: clientId,
          memberId: memberId,
        );
        if (!ok) {
          debugPrint('[FamilyProvider] Failed to remove member on backend');
        }
      }
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FamilyProvider] removeMember error: $e');
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
      return true;
    }
  }
}
