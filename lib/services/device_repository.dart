import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/device.dart';

abstract class DeviceRepository {
  Future<List<Device>?> load();
  Future<void> save(List<Device> devices);
}

class HiveDeviceRepository implements DeviceRepository {
  static const _boxName = 'smart_homz_devices';
  static const _devicesKey = 'devices_v1';

  Future<Box<String>> _box() => Hive.openBox<String>(_boxName);

  @override
  Future<List<Device>?> load() async {
    final Box<String> box;
    try {
      box = await _box();
    } on HiveError {
      return null;
    }
    final value = box.get(_devicesKey);
    if (value == null) return null;
    final items = jsonDecode(value) as List<dynamic>;
    return items
        .map((item) => Device.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> save(List<Device> devices) async {
    final value = jsonEncode(devices.map((item) => item.toJson()).toList());
    try {
      await (await _box()).put(_devicesKey, value);
    } on HiveError {
      return;
    }
  }
}

class MemoryDeviceRepository implements DeviceRepository {
  List<Device>? _stored;

  MemoryDeviceRepository([List<Device>? seed]) {
    if (seed != null) {
      _stored = seed.map((item) => Device.fromJson(item.toJson())).toList();
    }
  }

  @override
  Future<List<Device>?> load() async {
    return _stored?.map((item) => Device.fromJson(item.toJson())).toList();
  }

  @override
  Future<void> save(List<Device> devices) async {
    _stored = devices.map((item) => Device.fromJson(item.toJson())).toList();
  }
}
