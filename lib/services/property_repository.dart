import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/property_hierarchy.dart';

class PropertySnapshot {
  final List<ManagedProperty> properties;
  final List<ManagedFloor> floors;
  final List<ManagedRoom> rooms;

  const PropertySnapshot({
    required this.properties,
    required this.floors,
    required this.rooms,
  });
}

abstract class PropertyRepository {
  Future<PropertySnapshot?> load();
  Future<void> save(PropertySnapshot snapshot);
}

/// Hive-backed repository. The UI and providers do not depend on Hive, so this
/// can later be replaced by a Firebase repository without changing screens.
class HivePropertyRepository implements PropertyRepository {
  static const _boxName = 'smart_homz_properties';
  static const _snapshotKey = 'hierarchy_v1';

  Future<Box<String>> _box() => Hive.openBox<String>(_boxName);

  @override
  Future<PropertySnapshot?> load() async {
    final Box<String> box;
    try {
      box = await _box();
    } on HiveError {
      return null;
    }
    final value = box.get(_snapshotKey);
    if (value == null) return null;
    final json = jsonDecode(value) as Map<String, dynamic>;
    return PropertySnapshot(
      properties: (json['properties'] as List<dynamic>)
          .map(
            (item) => ManagedProperty.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      floors: (json['floors'] as List<dynamic>)
          .map(
            (item) =>
                ManagedFloor.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      rooms: (json['rooms'] as List<dynamic>)
          .map(
            (item) =>
                ManagedRoom.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<void> save(PropertySnapshot snapshot) async {
    final value = jsonEncode({
      'properties': snapshot.properties.map((item) => item.toJson()).toList(),
      'floors': snapshot.floors.map((item) => item.toJson()).toList(),
      'rooms': snapshot.rooms.map((item) => item.toJson()).toList(),
    });
    try {
      await (await _box()).put(_snapshotKey, value);
    } on HiveError {
      return;
    }
  }
}

class MemoryPropertyRepository implements PropertyRepository {
  PropertySnapshot? _stored;

  MemoryPropertyRepository([PropertySnapshot? seed]) {
    _stored = seed == null ? null : _copy(seed);
  }

  @override
  Future<PropertySnapshot?> load() async =>
      _stored == null ? null : _copy(_stored!);

  @override
  Future<void> save(PropertySnapshot snapshot) async {
    _stored = _copy(snapshot);
  }

  PropertySnapshot _copy(PropertySnapshot snapshot) {
    return PropertySnapshot(
      properties: snapshot.properties
          .map((item) => ManagedProperty.fromJson(item.toJson()))
          .toList(),
      floors: snapshot.floors
          .map((item) => ManagedFloor.fromJson(item.toJson()))
          .toList(),
      rooms: snapshot.rooms
          .map((item) => ManagedRoom.fromJson(item.toJson()))
          .toList(),
    );
  }
}
