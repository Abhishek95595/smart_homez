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
    final apiHomes = await _repository.getHomes(clientId);
    return apiHomes
        .map(
          (h) => HomeModel(
            id: h.id,
            name: h.name,
            address: h.address,
            latitude: h.latitude,
            longitude: h.longitude,
          ),
        )
        .toList();
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
    final floors = await _repository.getFloors(clientId, homeId);
    return floors
        .map(
          (f) => FloorModel(id: f.id, name: f.name, floorNumber: f.floorNumber),
        )
        .toList();
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
    required int floorNumber,
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
    final rooms = await _repository.getRooms(clientId, homeId, floorId);
    return rooms.map((r) => RoomModel(id: r.id, name: r.name)).toList();
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
}
