import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/device_model.dart';
import '../models/telemetry.dart';
import '../models/user_role.dart';
import '../services/device_repository.dart';
import '../services/device_service.dart';
import '../services/device_realtime_service.dart';
import '../services/sse_service.dart';
import '../services/hierarchy_service.dart';

class DeviceProvider extends ChangeNotifier {
  DeviceProvider({DeviceRepository? repository})
    : _repository = repository ?? HiveDeviceRepository() {
    _load();
  }

  final DeviceRepository _repository;
  final DeviceService _deviceService = DeviceService();
  final SseService _sseService = SseService();
  final HierarchyService _hierarchyService = HierarchyService();

  final List<Device> _devices = <Device>[];
  final Map<String, Telemetry> _latestTelemetry = <String, Telemetry>{};
  final Set<String> _updatingDeviceIds = <String>{};

  StreamSubscription<Map<String, dynamic>>? _sseSubscription;
  StreamSubscription<List<DeviceModel>>? _pollingSubscription;

  bool _isLoading = true;
  bool _isDisposed = false;
  String? _loadError;
  String? _clientId;

  List<Device> get devices => List<Device>.unmodifiable(_devices);

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

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

  int get onlineCount =>
      _devices.where((d) => d.status == DeviceStatus.online).length;

  int get offlineCount =>
      _devices.where((d) => d.status == DeviceStatus.offline).length;

  int get totalCount => _devices.length;

  bool isUpdating(String deviceId) {
    return _updatingDeviceIds.contains(deviceId);
  }

  Telemetry? telemetryFor(String deviceId) {
    return _latestTelemetry[deviceId];
  }

  void setClientId(String? id) {
    final String? cleanId = id?.trim();

    if (_clientId == cleanId) {
      return;
    }

    _clientId = cleanId;

    _devices.clear();
    _latestTelemetry.clear();

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Device? deviceById(String deviceId) {
    for (final Device device in _devices) {
      if (device.deviceId == deviceId) {
        return device;
      }
    }
    return null;
  }

  Future<void> reload() async {
    _isLoading = true;
    _loadError = null;
    _devices.clear();
    _latestTelemetry.clear();

    if (!_isDisposed) {
      notifyListeners();
    }

    await _load();
  }

  /// Loads the latest device list from the backend.
  Future<void> syncFromApi(String clientId) async {
    final String cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      _loadError = 'Client ID is missing.';
      return;
    }

    _clientId = cleanClientId;
    _isLoading = true;
    _loadError = null;

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final List<DeviceModel> apiDevices = await _deviceService.getDevices(
        cleanClientId,
      );

      _applyApiDevices(apiDevices, replaceAll: true);

      await _save();
    } catch (error) {
      _loadError = error.toString().replaceFirst('Exception: ', '');
      debugPrint('[DeviceProvider] Device sync notice: $error');
      if (_devices.isEmpty) {
        _devices.addAll(MockData.demoDevices());
      }
    } finally {
      _isLoading = false;

      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// Starts a safe polling-based real-time sync.
  Future<void> startRealtimeSync(
    String clientId, {
    Duration refreshInterval = const Duration(seconds: 5),
  }) async {
    final String cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      debugPrint(
        '[DeviceProvider] Cannot start realtime sync: '
        'client ID is empty.',
      );
      return;
    }

    _clientId = cleanClientId;

    await _pollingSubscription?.cancel();

    _pollingSubscription = RealtimeService.instance.deviceStream.listen(
      (List<DeviceModel> apiDevices) {
        _applyApiDevices(apiDevices);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[DeviceProvider] Realtime polling error: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    await RealtimeService.instance.start(
      clientId: cleanClientId,
      refreshInterval: refreshInterval,
    );
  }

  Future<void> stopRealtimeSync() async {
    await _pollingSubscription?.cancel();
    _pollingSubscription = null;
    RealtimeService.instance.stop();
  }

  void startRealtime(String token) {
    _sseSubscription?.cancel();
    _sseService.startListening(token);

    _sseSubscription = _sseService.eventStream.listen((event) {
      final String? deviceId = (event['device_id'] ?? event['deviceId'])
          ?.toString();

      if (deviceId == null || deviceId.isEmpty) {
        return;
      }

      final int index = _devices.indexWhere(
        (device) => device.deviceId == deviceId,
      );

      if (index == -1) {
        return;
      }

      final bool? parsedIsOn = _parseBooleanState(
        event['is_on'] ?? event['isOn'] ?? event['state'],
      );

      final double? brightness = _toDouble(event['brightness']);

      if (parsedIsOn != null) {
        _devices[index] = _devices[index].copyWith(isOn: parsedIsOn);
      }

      if (brightness != null) {
        _devices[index].dimLevel = brightness;
      }

      _latestTelemetry[deviceId] = Telemetry(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        power: _toDouble(event['power']),
        gasPpm: _toDouble(event['gas_ppm']),
        temperature: _toDouble(event['temperature']),
      );

      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  void stopRealtime() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseService.stopListening();
  }

  void _applyApiDevices(
    List<DeviceModel> apiDevices, {
    bool replaceAll = false,
  }) {
    if (replaceAll) {
      _devices
        ..clear()
        ..addAll(apiDevices.map(_mapApiDevice));
    } else {
      for (final DeviceModel apiDevice in apiDevices) {
        final int index = _devices.indexWhere(
          (device) => device.deviceId == apiDevice.id,
        );

        if (index == -1) {
          _devices.add(_mapApiDevice(apiDevice));
          continue;
        }

        final Device current = _devices[index];

        final bool keepLocalState = _updatingDeviceIds.contains(apiDevice.id);

        _devices[index] = current.copyWith(
          name: apiDevice.name,
          type: _mapType(apiDevice.subtype ?? apiDevice.type),
          status: apiDevice.isOnline
              ? DeviceStatus.online
              : DeviceStatus.offline,
          buildingId: apiDevice.homeId ?? current.buildingId,
          floorId: apiDevice.floorId ?? current.floorId,
          roomId: apiDevice.roomId ?? current.roomId,
          homeName: apiDevice.homeName ?? current.homeName,
          floorName: apiDevice.floorName ?? current.floorName,
          roomName: apiDevice.roomName ?? current.roomName,
          zone: apiDevice.roomName ?? apiDevice.zone ?? current.zone,
          lastHeartbeat: apiDevice.lastUpdated ?? DateTime.now(),
          isOn: keepLocalState ? current.isOn : apiDevice.isOn,
        );

        if (apiDevice.brightness != null) {
          _devices[index].dimLevel = apiDevice.brightness!.toDouble();
        }
      }

      final Set<String> apiIds = apiDevices.map((device) => device.id).toSet();

      _devices.removeWhere(
        (device) =>
            device.tenantId == _clientId && !apiIds.contains(device.deviceId),
      );
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Device _mapApiDevice(DeviceModel model) {
    return Device(
      deviceId: model.id,
      name: model.name,
      type: _mapType(model.subtype ?? model.type),
      status: model.isOnline ? DeviceStatus.online : DeviceStatus.offline,
      buildingId: model.homeId ?? '',
      floorId: model.floorId,
      roomId: model.roomId,
      homeName: model.homeName,
      floorName: model.floorName,
      roomName: model.roomName,
      zone: model.roomName ?? model.zone ?? 'Unassigned',
      lastHeartbeat: model.lastUpdated ?? DateTime.now(),
      firmwareVersion: '1.0.0',
      macAddress: 'UNKNOWN',
      tenantId: _clientId ?? '',
      isOn: model.isOn,
      dimLevel: model.brightness?.toDouble(),
    );
  }

  DeviceType _mapType(String? apiType) {
    switch (apiType?.trim().toLowerCase()) {
      case 'light':
      case 'tubelight':
      case 'bulb':
        return DeviceType.light;
      case 'fan':
        return DeviceType.fan;
      case 'ac':
      case 'air_conditioner':
        return DeviceType.ac;
      case 'pump':
        return DeviceType.pump;
      case 'smoke_sensor':
      case 'smoke sensor':
        return DeviceType.smokeSensor;
      case 'gas_sensor':
      case 'gas sensor':
        return DeviceType.gasSensor;
      case 'energy_meter':
      case 'energy meter':
        return DeviceType.energyMeter;
      default:
        return DeviceType.light;
    }
  }

  List<Device> visibleDevicesForProperty(AppUser? user, String propertyName) {
    final String target = propertyName.trim().toLowerCase();
    return visibleDevices(user).where((d) {
      return d.homeName?.trim().toLowerCase() == target ||
          d.buildingId == propertyName;
    }).toList();
  }

  List<Device> visibleDevicesForFloor(
    AppUser? user, {
    required String propertyName,
    required String floorName,
  }) {
    final String targetHome = propertyName.trim().toLowerCase();
    final String targetFloor = floorName.trim().toLowerCase();
    return visibleDevices(user).where((d) {
      final bool homeMatch =
          d.homeName?.trim().toLowerCase() == targetHome ||
          d.buildingId == propertyName;
      final bool floorMatch =
          d.floorName?.trim().toLowerCase() == targetFloor ||
          d.floorId == floorName;
      return homeMatch && floorMatch;
    }).toList();
  }

  List<Device> visibleDevicesForRoom(
    AppUser? user, {
    required String propertyName,
    required String floorName,
    required String roomName,
  }) {
    final String targetHome = propertyName.trim().toLowerCase();
    final String targetFloor = floorName.trim().toLowerCase();
    final String targetRoom = roomName.trim().toLowerCase();
    return visibleDevices(user).where((d) {
      final bool homeMatch =
          d.homeName?.trim().toLowerCase() == targetHome ||
          d.buildingId == propertyName;
      final bool floorMatch =
          d.floorName?.trim().toLowerCase() == targetFloor ||
          d.floorId == floorName;
      final bool roomMatch =
          d.roomName?.trim().toLowerCase() == targetRoom ||
          d.roomId == roomName;
      return homeMatch && floorMatch && roomMatch;
    }).toList();
  }

  List<Device> visibleDevices(AppUser? user) {
    if (user == null) {
      return const <Device>[];
    }

    switch (user.role) {
      case UserRole.superAdmin:
      case UserRole.facilityManager:
      case UserRole.maintenance:
        return _devices;
      case UserRole.security:
        return _devices
            .where(
              (device) => device.type.isSensorOnly || device.flatId == null,
            )
            .toList();
      case UserRole.resident:
        return _devices;
    }
  }

  bool canControlDevice(Device device, AppUser? user) {
    if (user == null || !device.type.isControllable) {
      return false;
    }

    final bool belongsToCustomer =
        device.tenantId == user.id || device.tenantId == user.tenantId;

    switch (user.role) {
      case UserRole.superAdmin:
      case UserRole.facilityManager:
        return true;
      case UserRole.maintenance:
        return belongsToCustomer || device.flatId == null;
      case UserRole.resident:
        return true;
      case UserRole.security:
        return false;
    }
  }

  Future<bool> toggleDevice(
    Device device, {
    String requestedBy = 'app_user',
  }) async {
    final int index = _devices.indexWhere(
      (item) => item.deviceId == device.deviceId,
    );

    if (index == -1 || _updatingDeviceIds.contains(device.deviceId)) {
      return false;
    }

    final String? clientId = _clientId;

    if (clientId == null || clientId.trim().isEmpty) {
      return false;
    }

    final bool previousState = _devices[index].isOn;
    final bool newState = !previousState;
    final String command = newState ? 'on' : 'off';

    _updatingDeviceIds.add(device.deviceId);

    _devices[index] = _devices[index].copyWith(isOn: newState);

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final bool success = await _deviceService.sendCommand(
        clientId,
        device.deviceId,
        command,
        null,
      );

      if (!success) {
        _devices[index] = _devices[index].copyWith(isOn: previousState);
        return false;
      }

      await RealtimeService.instance.refreshNow();
      await _save();
      return true;
    } catch (error) {
      _devices[index] = _devices[index].copyWith(isOn: previousState);
      return false;
    } finally {
      _updatingDeviceIds.remove(device.deviceId);

      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<bool> setDevicePower(
    Device device,
    bool targetState, {
    String requestedBy = 'app_user',
  }) async {
    final int index = _devices.indexWhere(
      (item) => item.deviceId == device.deviceId,
    );

    if (index == -1 || _updatingDeviceIds.contains(device.deviceId)) {
      return false;
    }

    final String? clientId = _clientId;
    if (clientId == null || clientId.trim().isEmpty) {
      _devices[index] = _devices[index].copyWith(isOn: targetState);
      if (!_isDisposed) notifyListeners();
      await _save();
      return true;
    }

    final bool previousState = _devices[index].isOn;
    final String command = targetState ? 'on' : 'off';

    _updatingDeviceIds.add(device.deviceId);
    _devices[index] = _devices[index].copyWith(isOn: targetState);

    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final bool success = await _deviceService.sendCommand(
        clientId,
        device.deviceId,
        command,
        null,
      );

      if (!success) {
        _devices[index] = _devices[index].copyWith(isOn: previousState);
        return false;
      }

      await RealtimeService.instance.refreshNow();
      await _save();
      return true;
    } catch (error) {
      _devices[index] = _devices[index].copyWith(isOn: previousState);
      return false;
    } finally {
      _updatingDeviceIds.remove(device.deviceId);
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<bool> setDevicePowerById(String deviceId, bool targetState) async {
    final int index = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (index != -1) {
      return setDevicePower(_devices[index], targetState);
    }
    return false;
  }

  void setDevicePowerLocally(String deviceId, bool targetState) {
    final int index = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(isOn: targetState);
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> setDimLevel(Device device, double value) async {
    final int index = _devices.indexWhere(
      (item) => item.deviceId == device.deviceId,
    );

    if (index == -1) {
      return;
    }

    final String? clientId = _clientId;

    if (clientId == null || clientId.isEmpty) {
      return;
    }

    final bool success = await _deviceService.sendCommand(
      clientId,
      device.deviceId,
      'brightness',
      value.clamp(0, 100).round(),
    );

    if (success) {
      _devices[index].dimLevel = value.clamp(0, 100);
      await _save();

      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  bool deviceNameExists(String roomId, String name, {String? excludingId}) {
    final String normalized = name.trim().toLowerCase();

    if (normalized.isEmpty) {
      return false;
    }

    return _devices.any(
      (item) =>
          item.deviceId != excludingId &&
          item.roomId == roomId &&
          item.name.toLowerCase() == normalized,
    );
  }

  bool macAddressExists(String address, {String? excludingId}) {
    final String normalized = address.trim().toUpperCase();

    if (normalized.isEmpty) {
      return false;
    }

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
    final Device item = Device(
      deviceId: 'device_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      name: name.trim().isEmpty ? type.label : name.trim(),
      firmwareVersion: '1.0.0',
      macAddress: macAddress.trim().toUpperCase(),
      tenantId: _clientId ?? 'aurabrain',
      buildingId: propertyId?.trim() ?? '',
      floorId: floorId?.trim(),
      roomId: roomId?.trim(),
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
    final int index = _devices.indexWhere(
      (item) => item.deviceId == device.deviceId,
    );

    if (index == -1) {
      return;
    }

    if (_clientId != null && !device.deviceId.startsWith('device_')) {
      await _hierarchyService.renameDevice(
        clientId: _clientId!,
        deviceId: device.deviceId,
        name: name,
      );
      await syncFromApi(_clientId!);
      return;
    }

    _devices[index] = device.copyWith(
      type: type,
      name: name.trim().isEmpty ? device.name : name.trim(),
      macAddress: macAddress.trim().toUpperCase(),
    );

    await _saveAndNotify();
  }

  Future<void> deleteDevice(String deviceId) async {
    if (_clientId != null && !deviceId.startsWith('device_')) {
      await _hierarchyService.deleteDevice(
        clientId: _clientId!,
        deviceId: deviceId,
      );
      await syncFromApi(_clientId!);
      return;
    }
    _devices.removeWhere((item) => item.deviceId == deviceId);
    _latestTelemetry.remove(deviceId);
    await _saveAndNotify();
  }

  Future<void> moveDevice(
    Device device, {
    String? roomId,
    String? floorId,
  }) async {
    final String? clientId = _clientId;
    if (clientId == null) return;

    if (roomId != null) {
      await _hierarchyService.moveDeviceToRoom(
        clientId: clientId,
        deviceId: device.deviceId,
        roomId: roomId,
      );
    } else if (floorId != null) {
      await _hierarchyService.moveDeviceToFloor(
        clientId: clientId,
        deviceId: device.deviceId,
        floorId: floorId,
      );
    }

    await syncFromApi(clientId);
  }

  Future<void> renameRoom(String roomId, String roomName) async {
    for (int index = 0; index < _devices.length; index++) {
      if (_devices[index].roomId == roomId) {
        _devices[index] = _devices[index].copyWith(zone: roomName);
      }
    }
    await _saveAndNotify();
  }

  Future<void> deleteDevicesForRoom(String roomId) async {
    _devices.removeWhere((item) => item.roomId == roomId);
    await _saveAndNotify();
  }

  Future<void> deleteDevicesForFloor(String floorId) async {
    _devices.removeWhere((item) => item.floorId == floorId);
    await _saveAndNotify();
  }

  Future<void> deleteDevicesForProperty(String propertyId) async {
    _devices.removeWhere((item) => item.buildingId == propertyId);
    await _saveAndNotify();
  }

  // Compatibility helpers
  int onlineCountFor(AppUser? user) => onlineCount;
  int offlineCountFor(AppUser? user) => offlineCount;
  int totalCountFor(AppUser? user) => totalCount;
  List<Device> fireAndSmokeDevicesFor(AppUser? user) => fireAndSmokeDevices;
  List<Device> visibleDevicesAt(
    AppUser? user, {
    String? buildingId,
    String? towerId,
    String? flatId,
    String? zone,
  }) {
    return visibleDevices(user).where((d) {
      if (buildingId != null && d.buildingId != buildingId) return false;
      if (zone != null && d.zone != zone) return false;
      return true;
    }).toList();
  }

  Future<void> _load() async {
    try {
      final List<Device>? stored = await _repository.load();

      if (stored != null) {
        _devices
          ..clear()
          ..addAll(stored);
      } else {
        _devices
          ..clear()
          ..addAll(MockData.demoDevices());
      }
    } catch (error) {
      _loadError = 'Could not load saved devices: $error';
    } finally {
      _isLoading = false;

      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _saveAndNotify() async {
    await _save();

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _save() {
    return _repository.save(_devices);
  }

  static bool? _parseBooleanState(dynamic value) {
    if (value is bool) {
      return value;
    }

    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    if (<String>{'on', 'true', '1', 'active'}.contains(normalized)) {
      return true;
    }

    if (<String>{'off', 'false', '0', 'inactive'}.contains(normalized)) {
      return false;
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _isDisposed = true;

    _sseSubscription?.cancel();
    _pollingSubscription?.cancel();

    _sseService.stopListening();
    RealtimeService.instance.stop();

    super.dispose();
  }
}
