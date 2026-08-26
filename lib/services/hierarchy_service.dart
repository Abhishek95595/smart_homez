import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/network/api_exception.dart';
import '../data/models/requests/add_vendor_account_request.dart';
import '../data/models/requests/move_device_request.dart';
import '../data/models/requests/pair_vendor_node_request.dart';
import '../data/models/requests/update_floor_request.dart';
import '../data/models/requests/update_home_request.dart';
import '../data/models/requests/update_room_request.dart';
import '../data/repositories/tenant_api_repository.dart';
import '../models/home_model.dart';
import '../models/floor_model.dart';
import '../models/room_model.dart';
import '../models/vendor_account_model.dart';
import '../models/vendor_node_model.dart';

/// Service to coordinate property hierarchy operations and data refreshes.
class HierarchyService {
  HierarchyService([TenantApiRepository? repository])
    : _repository = repository ?? TenantApiRepository();

  final TenantApiRepository _repository;

  // ============================================================
  // HOMES
  // ============================================================

  Future<List<HomeModel>> getHomes(String clientId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(
        message: 'Unauthenticated. Log in with Firebase first.',
        statusCode: 401,
      );
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('getHomes');
      final result = await callable.call();
      dynamic raw = result.data;
      if (raw is Map && raw['data'] != null) {
        raw = raw['data'];
      }
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (item) => HomeModel(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? 'Smart Home').toString(),
              address: (item['address'] ?? '').toString(),
              latitude: item['latitude'] != null
                  ? (item['latitude'] as num).toDouble()
                  : null,
              longitude: item['longitude'] != null
                  ? (item['longitude'] as num).toDouble()
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[HierarchyService] getHomes failed: $e');
      rethrow;
    }
  }

  Future<HomeModel?> createHome(
    String clientId,
    String name,
    String address,
  ) async {
    final h = await _repository.createHome(
      clientId,
      name: name,
      address: address,
    );
    if (h == null) return null;
    return HomeModel(
      id: h.id,
      name: h.name,
      address: h.address,
      latitude: h.latitude,
      longitude: h.longitude,
    );
  }

  Future<HomeModel> getHome({
    required String clientId,
    required String homeId,
  }) {
    return _repository.getHome(clientId: clientId, homeId: homeId);
  }

  Future<void> updateHome({
    required String clientId,
    required String homeId,
    required String name,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    await _repository.updateHome(
      clientId: clientId,
      homeId: homeId,
      request: UpdateHomeRequest(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<void> deleteHome(String clientId, String homeId) async {
    await _repository.deleteHome(clientId: clientId, homeId: homeId);
  }

  // ============================================================
  // FLOORS
  // ============================================================

  Future<List<FloorModel>> getFloors(String clientId, String homeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(
        message: 'Unauthenticated. Log in with Firebase first.',
        statusCode: 401,
      );
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('getFloors');
      final result = await callable.call(<String, dynamic>{'homeId': homeId});
      dynamic raw = result.data;
      if (raw is Map && raw['data'] != null) {
        raw = raw['data'];
      }
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (item) => FloorModel(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? 'Floor').toString(),
              floorNumber:
                  (item['floorNumber'] ?? item['floor_number'] ?? 0) is num
                  ? (item['floorNumber'] ?? item['floor_number'] as num).toInt()
                  : 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[HierarchyService] getFloors failed: $e');
      rethrow;
    }
  }

  Future<FloorModel?> createFloor(
    String clientId,
    String homeId,
    String name,
    int number,
  ) async {
    final f = await _repository.createFloor(
      clientId,
      homeId,
      name: name,
      floorNumber: number,
    );
    if (f == null) return null;
    return FloorModel(id: f.id, name: f.name, floorNumber: f.floorNumber);
  }

  Future<void> renameFloor({
    required String clientId,
    required String homeId,
    required String floorId,
    required String name,
    int floorNumber = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw const FormatException('Floor name cannot be empty.');
    }

    await _repository.updateFloor(
      clientId: clientId,
      homeId: homeId,
      floorId: floorId,
      request: UpdateFloorRequest(name: name, floorNumber: floorNumber),
    );
  }

  Future<void> deleteFloor({
    required String clientId,
    required String homeId,
    required String floorId,
  }) async {
    await _repository.deleteFloor(
      clientId: clientId,
      homeId: homeId,
      floorId: floorId,
    );
  }

  // ============================================================
  // ROOMS
  // ============================================================

  Future<List<RoomModel>> getRooms(
    String clientId,
    String homeId,
    String floorId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(
        message: 'Unauthenticated. Log in with Firebase first.',
        statusCode: 401,
      );
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('getRooms');
      final result = await callable.call(<String, dynamic>{
        'homeId': homeId,
        'floorId': floorId,
      });
      dynamic raw = result.data;
      if (raw is Map && raw['data'] != null) {
        raw = raw['data'];
      }
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      return list
          .whereType<Map>()
          .map(
            (item) => RoomModel(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? 'Room').toString(),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[HierarchyService] getRooms failed: $e');
      rethrow;
    }
  }

  Future<RoomModel?> createRoom(
    String clientId,
    String homeId,
    String floorId,
    String name,
  ) async {
    final r = await _repository.createRoom(
      clientId,
      homeId,
      floorId,
      name: name,
    );
    if (r == null) return null;
    return RoomModel(id: r.id, name: r.name);
  }

  Future<void> renameRoom({
    required String clientId,
    required String homeId,
    required String floorId,
    required String roomId,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      throw const FormatException('Room name cannot be empty.');
    }

    await _repository.updateRoom(
      clientId: clientId,
      homeId: homeId,
      floorId: floorId,
      roomId: roomId,
      request: UpdateRoomRequest(name: name),
    );
  }

  Future<void> deleteRoom({
    required String clientId,
    required String homeId,
    required String floorId,
    required String roomId,
  }) async {
    await _repository.deleteRoom(
      clientId: clientId,
      homeId: homeId,
      floorId: floorId,
      roomId: roomId,
    );
  }

  // ============================================================
  // DEVICES
  // ============================================================

  Future<void> renameDevice({
    required String clientId,
    required String deviceId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const FormatException('Device name cannot be empty.');
    }

    await _repository.updateDeviceName(
      clientId: clientId,
      deviceId: deviceId,
      name: trimmedName,
    );
  }

  Future<void> deleteDevice({
    required String clientId,
    required String deviceId,
  }) async {
    await _repository.deleteDevice(clientId: clientId, deviceId: deviceId);
  }

  Future<void> moveDeviceToRoom({
    required String clientId,
    required String deviceId,
    required String roomId,
  }) {
    return _repository.moveDevice(
      clientId: clientId,
      deviceId: deviceId,
      request: MoveDeviceRequest.toRoom(roomId),
    );
  }

  Future<void> moveDeviceToFloor({
    required String clientId,
    required String deviceId,
    required String floorId,
  }) {
    return _repository.moveDevice(
      clientId: clientId,
      deviceId: deviceId,
      request: MoveDeviceRequest.toFloor(floorId),
    );
  }

  // ============================================================
  // VENDOR METHODS
  // ============================================================

  Future<List<VendorAccountModel>> getVendorAccounts(String clientId) {
    return _repository.getVendorAccounts(clientId);
  }

  Future<VendorAccountModel> addVendorAccount({
    required String clientId,
    required String vendorDefinitionId,
    String? apiKey,
  }) {
    return _repository.addVendorAccount(
      clientId: clientId,
      request: AddVendorAccountRequest(
        vendorDefinitionId: vendorDefinitionId,
        apiKey: apiKey,
      ),
    );
  }

  Future<void> deleteVendorAccount({
    required String clientId,
    required String accountId,
  }) {
    return _repository.deleteVendorAccount(
      clientId: clientId,
      accountId: accountId,
    );
  }

  Future<void> syncVendorAccounts(String clientId) {
    return _repository.syncVendorAccounts(clientId);
  }

  Future<List<VendorNodeModel>> getUnpairedVendorNodes(String clientId) {
    return _repository.getUnpairedVendorNodes(clientId);
  }

  Future<void> pairVendorNodeToRoom({
    required String clientId,
    required String nodeId,
    required String roomId,
  }) {
    return _repository.pairVendorNode(
      clientId: clientId,
      nodeId: nodeId,
      request: PairVendorNodeRequest.toRoom(roomId),
    );
  }

  Future<void> pairVendorNodeToFloor({
    required String clientId,
    required String nodeId,
    required String floorId,
  }) {
    return _repository.pairVendorNode(
      clientId: clientId,
      nodeId: nodeId,
      request: PairVendorNodeRequest.toFloor(floorId),
    );
  }

  // ============================================================
  // TEMPLATE SETUP & BATCH ROOM ASSIGNMENTS
  // ============================================================

  /// Creates a Home and seeds its rooms from chosen layout template.
  Future<Map<String, dynamic>?> setupHomeFromTemplate({
    required String template,
    required String homeName,
    String? address,
  }) async {
    return _repository.setupHomeFromTemplate(
      template: template,
      homeName: homeName,
      address: address,
    );
  }

  /// Batch-assigns a list of (DeviceId, RoomId) pairs within a home.
  Future<bool> bulkAssignDevicesToRooms(
    List<Map<String, String>> assignments,
  ) async {
    return _repository.bulkAssignDevicesToRooms(assignments);
  }

  /// Lists unassigned devices in a home with smart-suggested room.
  Future<List<Map<String, dynamic>>> getUnassignedDevices(String homeId) async {
    return _repository.getUnassignedDevices(homeId);
  }
}
