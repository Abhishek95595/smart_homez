import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/telemetry.dart';
import '../models/user_role.dart';
import '../services/realtime_service.dart';
import '../services/device_repository.dart';
import '../services/tenant_api_repository.dart';

/// Manages device registry + live state. Wraps command sending
/// (would publish to anvya/{tenant}/{building}/{device}/command in prod).
class DeviceProvider extends ChangeNotifier {
  final DeviceRepository _repository;
  final TenantApiRepository _apiRepo = TenantApiRepository();
  final List<Device> _devices = MockData.demoDevices();
  final Map<String, Telemetry> _latestTelemetry = {};
  StreamSubscription<Telemetry>? _sub;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _loadError;
  String? _clientId;

  DeviceProvider({DeviceRepository? repository})
    : _repository = repository ?? HiveDeviceRepository() {
    _load();
  }

  List<Device> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  void setClientId(String? id) {
    _clientId = id;
  }

  List<Device> get controllableDevices =>
      _devices.where((d) => d.type.isControllable).toList();

  List<Device> get sensorDevices =>
      _devices.where((d) => d.type.isSensorOnly).toList();

  List<Device> get fireAndSmokeDevices => _devices
      .where(
        (device) =>
            device.type == DeviceType.smokeSensor ||
            device.type == DeviceType.gasSensor,
      )
      .toList();

  Telemetry? telemetryFor(String deviceId) => _latestTelemetry[deviceId];

  String _nextAvailableDeviceName(DeviceType type, {String? roomId}) {
    final base = type.label;
    final locationId = roomId?.trim() ?? '';
    final names = _devices
        .where((device) => (device.roomId ?? '') == locationId)
        .map((device) => device.name.trim().toLowerCase())
        .toSet();
    if (!names.contains(base.toLowerCase())) return base;
    var suffix = 2;
    while (names.contains('$base $suffix'.toLowerCase())) {
      suffix++;
    }
    return '$base $suffix';
  }

  Device? deviceById(String deviceId) =>
      _devices.where((item) => item.deviceId == deviceId).firstOrNull;

  Future<void> reload() async {
    _isLoading = true;
    _loadError = null;
    _devices
      ..clear()
      ..addAll(MockData.demoDevices());
    _latestTelemetry.clear();
    notifyListeners();
    await _load();
  }

  Future<void> syncFromApi(String clientId) async {
    _clientId = clientId;
    _isLoading = true;
    notifyListeners();

    try {
      final apiDevices = await _apiRepo.getDevices(clientId);
      if (apiDevices.isNotEmpty) {
        _devices.clear();
        for (final d in apiDevices) {
          _devices.add(Device(
            deviceId: d.id,
            name: d.name,
            type: _mapType(d.type),
            status: _mapStatus(d.status),
            buildingId: d.homeId ?? '',
            floorId: d.floorId,
            roomId: d.roomId,
            zone: d.zone ?? 'Unassigned',
            lastHeartbeat: DateTime.now(),
            firmwareVersion: '1.0.0',
            macAddress: 'UNKNOWN',
            tenantId: clientId,
          ));
        }
        await _save();
      }
    } catch (e) {
      debugPrint('Device Sync Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DeviceType _mapType(String? apiType) {
    switch (apiType?.toLowerCase()) {
      case 'light': return DeviceType.light;
      case 'fan': return DeviceType.fan;
      case 'ac': return DeviceType.ac;
      case 'pump': return DeviceType.pump;
      case 'smoke_sensor': return DeviceType.smokeSensor;
      case 'gas_sensor': return DeviceType.gasSensor;
      case 'energy_meter': return DeviceType.energyMeter;
      default: return DeviceType.light;
    }
  }

  DeviceStatus _mapStatus(String? apiStatus) {
    return apiStatus?.toLowerCase() == 'online' 
        ? DeviceStatus.online 
        : DeviceStatus.offline;
  }

  int get onlineCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;
  int get offlineCount =>
      _devices.where((d) => d.status == DeviceStatus.offline).length;
  int get totalCount => _devices.length;

  void startRealtime() {
    RealtimeService.instance.start(_devices);
    _sub = RealtimeService.instance.telemetryStream.listen((t) {
      _latestTelemetry[t.deviceId] = t;
      notifyListeners();
    });
  }

  void stopRealtime() {
    _sub?.cancel();
    RealtimeService.instance.stop();
  }

  List<Device> devicesForZone(String zone) =>
      _devices.where((d) => d.zone == zone).toList();

  List<Device> devicesForRoom(String roomId) =>
      _devices.where((d) => d.roomId == roomId).toList();

  List<String> get zones => _devices.map((d) => d.zone).toSet().toList();

  // ---------------------------------------------------------------------
  // Role-based scoping (RBAC)
  // ---------------------------------------------------------------------

  /// Devices visible to the given user, per PRD role matrix:
  /// - Super Admin / Facility Manager: full building/tower hierarchy.
  /// - Maintenance: full visibility (needs to diagnose/fix any device).
  /// - Security: only safety sensors + common-area devices (no private flats).
  /// - Resident: only their own flat's devices + shared/common devices.
  List<Device> visibleDevices(AppUser? user) {
    if (user == null) return const [];
    switch (user.role) {
      case UserRole.superAdmin:
      case UserRole.facilityManager:
      case UserRole.maintenance:
        return _devices;
      case UserRole.security:
        return _devices
            .where((d) => d.type.isSensorOnly || d.flatId == null)
            .toList();
      case UserRole.resident:
        return _devices
            .where((d) => d.flatId == null || _belongsToResident(d, user))
            .toList();
    }
  }

  bool _belongsToResident(Device device, AppUser user) {
    final residentFlat = user.flatId;
    final deviceFlat = device.flatId;
    if (residentFlat == null || deviceFlat == null) return false;
    return deviceFlat == residentFlat ||
        deviceFlat == 'flat_$residentFlat' ||
        deviceFlat.endsWith('_$residentFlat');
  }

  /// Whether [user] is permitted to issue a command (toggle/dim) to [device].
  /// - Super Admin / Facility Manager: any controllable device.
  /// - Maintenance: common/shared infrastructure (pumps, scenes) — not
  ///   private in-flat devices belonging to residents.
  /// - Resident: only controllable devices inside their own flat.
  /// - Security: view-only, cannot control anything.
  bool canControlDevice(Device device, AppUser? user) {
    if (user == null || !device.type.isControllable) return false;
    switch (user.role) {
      case UserRole.superAdmin:
      case UserRole.facilityManager:
        return true;
      case UserRole.maintenance:
        return device.flatId == null;
      case UserRole.resident:
        return _belongsToResident(device, user);
      case UserRole.security:
        return false;
    }
  }

  List<String> zonesFor(AppUser? user) =>
      visibleDevices(user).map((d) => d.zone).toSet().toList();

  List<Device> devicesForZoneScoped(String zone, AppUser? user) =>
      visibleDevices(user).where((d) => d.zone == zone).toList();

  /// Returns the role-visible devices at one level of the property hierarchy.
  /// Any omitted location field is treated as "all" for that level.
  List<Device> visibleDevicesAt(
    AppUser? user, {
    String? buildingId,
    String? towerId,
    String? flatId,
    String? zone,
  }) {
    return visibleDevices(user).where((device) {
      if (buildingId != null && device.buildingId != buildingId) return false;
      if (towerId != null && device.towerId != towerId) return false;
      if (flatId != null && device.flatId != flatId) return false;
      if (zone != null && device.zone != zone) return false;
      return true;
    }).toList();
  }

  List<Device> controllableDevicesFor(AppUser? user) => visibleDevices(
    user,
  ).where((d) => d.type.isControllable && canControlDevice(d, user)).toList();

  List<Device> fireAndSmokeDevicesFor(AppUser? user) => visibleDevices(user)
      .where(
        (device) =>
            device.type == DeviceType.smokeSensor ||
            device.type == DeviceType.gasSensor,
      )
      .toList();

  int onlineCountFor(AppUser? user) =>
      visibleDevices(user).where((d) => d.status == DeviceStatus.online).length;

  int offlineCountFor(AppUser? user) => visibleDevices(
    user,
  ).where((d) => d.status == DeviceStatus.offline).length;

  int totalCountFor(AppUser? user) => visibleDevices(user).length;

  /// Toggles device on/off; in production sends MQTT command payload via
  /// device.buildCommandPayload(command: 'relay_on'/'relay_off', ...).
  Future<void> toggleDevice(Device device, {String requestedBy = 'app_user'}) async {
    final idx = _devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (idx == -1) return;
    
    final newState = !_devices[idx].isOn;
    
    // API Call
    final success = await _apiRepo.toggleDevice(
      device.deviceId, 
      state: newState ? 1 : 0
    );

    if (success) {
      final updated = _devices[idx].copyWith(isOn: newState);
      _devices[idx] = updated;
      _save();
      notifyListeners();
    }
  }

  Future<void> setDimLevel(Device device, double value) async {
    final idx = _devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (idx == -1) return;

    // API Call
    final success = await _apiRepo.toggleDevice(
      device.deviceId, 
      brightness: value.toInt()
    );

    if (success) {
      _devices[idx].dimLevel = value;
      _save();
      notifyListeners();
    }
  }

  bool deviceNameExists(String roomId, String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _devices.any(
      (item) =>
          item.deviceId != excludingId &&
          item.roomId == roomId &&
          item.name.toLowerCase() == normalized,
    );
  }

  bool macAddressExists(String address, {String? excludingId}) {
    final normalized = address.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    return _devices.any(
      (item) =>
          item.deviceId != excludingId &&
          item.macAddress.toUpperCase() == normalized,
    );
  }

  Future<Device> addDevice({
    required DeviceType type,
    required String name,
    required String macAddress,
    String? propertyId,
    String? floorId,
    String? roomId,
    String? roomName,
  }) async {
    final resolvedRoomId = roomId?.trim();
    final resolvedFloorId = floorId?.trim();
    final resolvedName = name.trim().isEmpty
        ? _nextAvailableDeviceName(type, roomId: resolvedRoomId)
        : name.trim();
    final item = Device(
      deviceId: 'device_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      name: resolvedName,
      firmwareVersion: '1.0.0',
      macAddress: macAddress.trim().toUpperCase(),
      tenantId: MockData.tenantId,
      buildingId: propertyId?.trim() ?? '',
      floorId: resolvedFloorId == null || resolvedFloorId.isEmpty
          ? null
          : resolvedFloorId,
      roomId: resolvedRoomId == null || resolvedRoomId.isEmpty
          ? null
          : resolvedRoomId,
      towerId: resolvedFloorId == null || resolvedFloorId.isEmpty
          ? null
          : resolvedFloorId,
      zone: roomName?.trim().isNotEmpty == true
          ? roomName!.trim()
          : 'Unassigned',
      lastHeartbeat: DateTime.now(),
    );
    _devices.add(item);
    await _saveAndNotify();
    return item;
  }

  Future<void> updateDevice(
    Device device, {
    required DeviceType type,
    required String name,
    required String macAddress,
  }) async {
    final index = _devices.indexWhere(
      (item) => item.deviceId == device.deviceId,
    );
    if (index == -1) return;
    _devices[index] = device.copyWith(
      type: type,
      name: name.trim().isEmpty ? device.name : name.trim(),
      macAddress: macAddress.trim().toUpperCase(),
    );
    await _saveAndNotify();
  }

  Future<void> deleteDevice(String deviceId) async {
    _devices.removeWhere((item) => item.deviceId == deviceId);
    _latestTelemetry.remove(deviceId);
    await _saveAndNotify();
  }

  Future<void> renameRoom(String roomId, String roomName) async {
    var changed = false;
    for (var index = 0; index < _devices.length; index++) {
      final item = _devices[index];
      if (item.roomId == roomId && item.zone != roomName.trim()) {
        _devices[index] = item.copyWith(zone: roomName.trim());
        changed = true;
      }
    }
    if (changed) await _saveAndNotify();
  }

  Future<void> deleteDevicesForRoom(String roomId) async {
    final ids = _devices
        .where((item) => item.roomId == roomId)
        .map((item) => item.deviceId)
        .toSet();
    _devices.removeWhere((item) => ids.contains(item.deviceId));
    _latestTelemetry.removeWhere((key, value) => ids.contains(key));
    await _saveAndNotify();
  }

  Future<void> deleteDevicesForFloor(String floorId) async {
    final ids = _devices
        .where((item) => item.floorId == floorId)
        .map((item) => item.deviceId)
        .toSet();
    _devices.removeWhere((item) => ids.contains(item.deviceId));
    _latestTelemetry.removeWhere((key, value) => ids.contains(key));
    await _saveAndNotify();
  }

  Future<void> deleteDevicesForProperty(String propertyId) async {
    final ids = _devices
        .where((item) => item.buildingId == propertyId)
        .map((item) => item.deviceId)
        .toSet();
    _devices.removeWhere((item) => ids.contains(item.deviceId));
    _latestTelemetry.removeWhere((key, value) => ids.contains(key));
    await _saveAndNotify();
  }

  Future<void> _load() async {
    try {
      final stored = await _repository.load();
      if (stored == null) {
        _attachLegacyRoomIds();
        await _save();
      } else {
        _devices
          ..clear()
          ..addAll(stored);
      }
    } catch (error) {
      _loadError = 'Could not load saved devices: $error';
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _attachLegacyRoomIds() {
    for (var index = 0; index < _devices.length; index++) {
      final device = _devices[index];
      String? roomId;
      if (device.flatId == 'flat_302') {
        switch (device.zone.toLowerCase()) {
          case 'living room':
            roomId = 'room_302_living';
            break;
          case 'bedroom':
            roomId = 'room_302_bedroom';
            break;
          case 'kitchen':
            roomId = 'room_302_kitchen';
            break;
        }
      }
      if (roomId != null) {
        _devices[index] = device.copyWith(floorId: 'floor_3', roomId: roomId);
      }
    }
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _repository.save(_devices);

  @override
  void dispose() {
    _isDisposed = true;
    _sub?.cancel();
    RealtimeService.instance.stop();
    super.dispose();
  }
}
