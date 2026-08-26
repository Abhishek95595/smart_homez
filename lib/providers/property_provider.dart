import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/property_hierarchy.dart';
import '../services/property_repository.dart';
import '../services/hierarchy_service.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  final HierarchyService _hierarchyService = HierarchyService();
  final Uuid _uuid;
  final List<ManagedProperty> _properties = [];
  final List<ManagedFloor> _floors = [];
  final List<ManagedRoom> _rooms = [];

  bool _isLoading = true;
  bool _isDisposed = false;
  String? _loadError;
  String? _clientId;

  PropertyProvider({PropertyRepository? repository, Uuid uuid = const Uuid()})
    : _repository = repository ?? HivePropertyRepository(),
      _uuid = uuid {
    _load();
  }

  void setClientId(String? id) {
    if (id == null || id == _clientId) return;
    final bool isDifferentClient = _clientId != null && _clientId != id;
    _clientId = id;
    if (isDifferentClient) {
      _properties.clear();
      _floors.clear();
      _rooms.clear();
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String? get clientId => _clientId;
  List<ManagedProperty> get properties => List.unmodifiable(_properties);
  List<ManagedFloor> get floors => List.unmodifiable(_floors);
  List<ManagedRoom> get rooms => List.unmodifiable(_rooms);

  String _nextAvailableName(String base, Iterable<String> currentNames) {
    final normalizedNames = currentNames
        .map((name) => name.trim().toLowerCase())
        .toSet();
    if (!normalizedNames.contains(base.toLowerCase())) return base;
    var suffix = 2;
    while (normalizedNames.contains('$base $suffix'.toLowerCase())) {
      suffix++;
    }
    return '$base $suffix';
  }

  List<ManagedFloor> floorsFor(String propertyId) {
    final result = _floors
        .where((item) => item.propertyId == propertyId)
        .toList();
    result.sort((a, b) => a.level.compareTo(b.level));
    return result;
  }

  List<ManagedRoom> roomsFor(String floorId) {
    final result = _rooms.where((item) => item.floorId == floorId).toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  List<ManagedRoom> roomsForHome(String propertyId) {
    final floorIds = floorsFor(propertyId).map((item) => item.id).toSet();
    final result = _rooms
        .where(
          (item) =>
              item.propertyId == propertyId ||
              (item.floorId != null && floorIds.contains(item.floorId)),
        )
        .toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  bool isFlatHome(String propertyId) => floorsFor(propertyId).isEmpty;

  ManagedProperty? propertyById(String id) =>
      _properties.where((item) => item.id == id).firstOrNull;

  ManagedFloor? floorById(String id) =>
      _floors.where((item) => item.id == id).firstOrNull;

  ManagedRoom? roomById(String id) =>
      _rooms.where((item) => item.id == id).firstOrNull;

  Future<void> reload() async {
    _isLoading = true;
    _loadError = null;
    _properties.clear();
    _floors.clear();
    _rooms.clear();
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _repository.load();
      _properties.clear();
      _floors.clear();
      _rooms.clear();
      if (snapshot == null) {
        _seedDefaults();
        await _save();
      } else {
        _properties.addAll(snapshot.properties);
        _floors.addAll(snapshot.floors);
        _rooms.addAll(snapshot.rooms);
      }
    } catch (error) {
      _loadError = 'Could not load saved properties: $error';
      _seedDefaults();
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _seedDefaults() {
    if (_properties.isNotEmpty || _clientId != null) return;
    _properties.addAll(const [
      ManagedProperty(
        id: 'bldg_A',
        name: 'Greenwood Heights',
        address: '221 Palm Avenue, Bengaluru',
        category: 'Residential',
        propertyType: 'Apartment',
      ),
      ManagedProperty(
        id: 'bldg_B',
        name: 'Palm View Residency',
        address: '456 Oak Lane, Bengaluru',
        category: 'Residential',
        propertyType: 'Apartment',
      ),
    ]);
  }

  /// Combined Hierarchy Sync
  Future<void> syncFromApi(String clientId) async {
    _clientId = clientId;
    _isLoading = true;
    notifyListeners();

    try {
      final apiHomes = await _hierarchyService.getHomes(clientId);

      _properties.clear();
      _floors.clear();
      _rooms.clear();

      if (apiHomes.isNotEmpty) {
        for (final h in apiHomes) {
          _properties.add(
            ManagedProperty(
              id: h.id,
              name: h.name,
              address: h.address ?? '',
              category: h.category ?? 'Residential',
              propertyType: h.propertyType ?? 'House',
              latitude: h.latitude?.toString(),
              longitude: h.longitude?.toString(),
            ),
          );

          final apiFloors = await _hierarchyService.getFloors(clientId, h.id);
          for (final f in apiFloors) {
            _floors.add(
              ManagedFloor(
                id: f.id,
                propertyId: h.id,
                name: f.name,
                level: f.floorNumber,
              ),
            );

            final apiRooms = await _hierarchyService.getRooms(
              clientId,
              h.id,
              f.id,
            );
            for (final r in apiRooms) {
              _rooms.add(
                ManagedRoom(
                  id: r.id,
                  floorId: f.id,
                  name: r.name,
                  type: 'Other',
                ),
              );
            }
          }
        }
      }
      await _save();
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[PropertyProvider] Property sync notice: $e');
      if (_properties.isEmpty) {
        _seedDefaults();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFloorsForHome(String homeId) async {
    final clientId = _clientId;
    if (clientId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final apiFloors = await _hierarchyService.getFloors(clientId, homeId);
      _floors.removeWhere((f) => f.propertyId == homeId);
      for (final f in apiFloors) {
        _floors.add(
          ManagedFloor(
            id: f.id,
            propertyId: homeId,
            name: f.name,
            level: f.floorNumber,
          ),
        );
      }
      await _save();
    } catch (e) {
      debugPrint('Fetch Floors Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomsForFloor(String homeId, String floorId) async {
    final clientId = _clientId;
    if (clientId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final apiRooms = await _hierarchyService.getRooms(
        clientId,
        homeId,
        floorId,
      );
      _rooms.removeWhere((r) => r.floorId == floorId);
      for (final r in apiRooms) {
        _rooms.add(
          ManagedRoom(id: r.id, floorId: floorId, name: r.name, type: 'Other'),
        );
      }
      await _save();
    } catch (e) {
      debugPrint('Fetch Rooms Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool propertyNameExists(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _properties.any(
      (item) => item.id != excludingId && item.name.toLowerCase() == normalized,
    );
  }

  bool floorExists(
    String propertyId, {
    required String name,
    required int level,
    String? excludingId,
  }) {
    final normalized = name.trim().toLowerCase();
    return _floors.any(
      (item) =>
          item.id != excludingId &&
          item.propertyId == propertyId &&
          (item.level == level || item.name.toLowerCase() == normalized),
    );
  }

  bool roomNameExists(
    String? floorId,
    String name, {
    String? propertyId,
    String? excludingId,
  }) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _rooms.any(
      (item) =>
          item.id != excludingId &&
          (floorId != null
              ? item.floorId == floorId
              : (propertyId != null
                    ? item.propertyId == propertyId
                    : item.floorId == null)) &&
          item.name.toLowerCase() == normalized,
    );
  }

  Future<ManagedProperty> addProperty({
    required String name,
    required String address,
    String category = 'Residential',
    String propertyType = 'House',
    String timezone = 'Asia/Kolkata',
    String currency = 'INR',
    String? businessStart,
    String? businessEnd,
  }) async {
    final enteredName = name.trim();
    final resolvedName = enteredName.isEmpty
        ? _nextAvailableName(
            'Untitled $propertyType',
            _properties.map((property) => property.name),
          )
        : enteredName;

    if (_clientId != null) {
      await _hierarchyService.createHome(_clientId!, resolvedName, address);
      await syncFromApi(_clientId!);
      return properties.last; // Approximate
    }

    final item = ManagedProperty(
      id: _uuid.v4(),
      name: resolvedName,
      address: address.trim(),
      category: category,
      propertyType: propertyType,
      timezone: timezone,
      currency: currency,
      businessStart: businessStart,
      businessEnd: businessEnd,
    );
    _properties.add(item);
    await _saveAndNotify();
    return item;
  }

  Future<void> updateProperty(
    ManagedProperty property, {
    required String name,
    required String address,
    String? category,
    String? propertyType,
    String? timezone,
    String? currency,
    String? businessStart,
    String? businessEnd,
  }) async {
    final index = _properties.indexWhere((item) => item.id == property.id);
    if (index == -1) return;
    final resolvedName = name.trim().isEmpty ? property.name : name.trim();

    if (_clientId != null && !property.id.startsWith('bldg_')) {
      await _hierarchyService.updateHome(
        clientId: _clientId!,
        homeId: property.id,
        name: resolvedName,
        address: address,
      );
      await syncFromApi(_clientId!);
      return;
    }

    _properties[index] = property.copyWith(
      name: resolvedName,
      address: address.trim(),
      category: category,
      propertyType: propertyType,
      timezone: timezone,
      currency: currency,
      businessStart: businessStart,
      businessEnd: businessEnd,
      clearBusinessHours: category?.toLowerCase() == 'residential',
    );
    await _saveAndNotify();
  }

  Future<void> deleteProperty(String propertyId) async {
    if (_clientId != null && !propertyId.startsWith('bldg_')) {
      await _hierarchyService.deleteHome(_clientId!, propertyId);
      await syncFromApi(_clientId!);
      return;
    }

    final floorIds = floorsFor(propertyId).map((item) => item.id).toSet();
    _rooms.removeWhere(
      (item) =>
          (item.floorId != null && floorIds.contains(item.floorId)) ||
          item.propertyId == propertyId,
    );
    _floors.removeWhere((item) => item.propertyId == propertyId);
    _properties.removeWhere((item) => item.id == propertyId);
    await _saveAndNotify();
  }

  Future<ManagedFloor> addFloor({
    required String propertyId,
    required String name,
    required int level,
  }) async {
    final resolvedName = name.trim().isEmpty ? 'Floor $level' : name.trim();

    if (_clientId != null && !propertyId.startsWith('bldg_')) {
      await _hierarchyService.createFloor(
        _clientId!,
        propertyId,
        resolvedName,
        level,
      );
      await fetchFloorsForHome(propertyId);
      return floors.last;
    }

    final item = ManagedFloor(
      id: _uuid.v4(),
      propertyId: propertyId,
      name: resolvedName,
      level: level,
    );
    _floors.add(item);
    await _saveAndNotify();
    return item;
  }

  Future<void> updateFloor(
    ManagedFloor floor, {
    required String name,
    required int level,
  }) async {
    final index = _floors.indexWhere((item) => item.id == floor.id);
    if (index == -1) return;
    final resolvedName = name.trim().isEmpty ? floor.name : name.trim();

    if (_clientId != null && !floor.id.contains('-')) {
      await _hierarchyService.renameFloor(
        clientId: _clientId!,
        homeId: floor.propertyId,
        floorId: floor.id,
        name: resolvedName,
        floorNumber: level,
      );
      await fetchFloorsForHome(floor.propertyId);
      return;
    }

    _floors[index] = floor.copyWith(name: resolvedName, level: level);
    await _saveAndNotify();
  }

  Future<void> deleteFloor(String floorId) async {
    final floor = floorById(floorId);
    if (floor != null && _clientId != null && !floor.id.contains('-')) {
      await _hierarchyService.deleteFloor(
        clientId: _clientId!,
        homeId: floor.propertyId,
        floorId: floorId,
      );
      await fetchFloorsForHome(floor.propertyId);
      return;
    }

    _rooms.removeWhere((item) => floorId == item.floorId);
    _floors.removeWhere((item) => item.id == floorId);
    await _saveAndNotify();
  }

  Future<ManagedRoom> addRoom({
    required String homeId,
    String? floorId,
    required String name,
    required String type,
  }) async {
    final enteredName = name.trim();
    final baseName = type.trim().isEmpty ? 'Room' : type.trim();
    final existingRooms = floorId != null
        ? _rooms.where((room) => room.floorId == floorId)
        : _rooms.where(
            (room) => room.propertyId == homeId || room.floorId == null,
          );

    final resolvedName = enteredName.isEmpty
        ? _nextAvailableName(baseName, existingRooms.map((room) => room.name))
        : enteredName;

    if (_clientId != null &&
        homeId.isNotEmpty &&
        !homeId.startsWith('bldg_') &&
        floorId != null) {
      await _hierarchyService.createRoom(
        _clientId!,
        homeId,
        floorId,
        resolvedName,
      );
      await fetchRoomsForFloor(homeId, floorId);
      return rooms.last;
    }

    final item = ManagedRoom(
      id: _uuid.v4(),
      floorId: floorId,
      propertyId: homeId,
      name: resolvedName,
      type: type,
    );
    _rooms.add(item);
    await _saveAndNotify();
    return item;
  }

  Future<void> updateRoom(
    ManagedRoom room, {
    required String name,
    required String type,
    String? homeId,
  }) async {
    final index = _rooms.indexWhere((item) => item.id == room.id);
    if (index == -1) return;
    final resolvedName = name.trim().isEmpty ? room.name : name.trim();

    if (_clientId != null &&
        homeId != null &&
        !homeId.startsWith('bldg_') &&
        room.floorId != null) {
      await _hierarchyService.renameRoom(
        clientId: _clientId!,
        homeId: homeId,
        floorId: room.floorId!,
        roomId: room.id,
        name: resolvedName,
      );
      await fetchRoomsForFloor(homeId, room.floorId!);
      return;
    }

    _rooms[index] = room.copyWith(name: resolvedName, type: type);
    await _saveAndNotify();
  }

  Future<void> deleteRoom(String roomId, {String? homeId}) async {
    final room = roomById(roomId);
    if (room != null &&
        _clientId != null &&
        homeId != null &&
        !homeId.startsWith('bldg_') &&
        room.floorId != null) {
      await _hierarchyService.deleteRoom(
        clientId: _clientId!,
        homeId: homeId,
        floorId: room.floorId!,
        roomId: roomId,
      );
      await fetchRoomsForFloor(homeId, room.floorId!);
      return;
    }

    _rooms.removeWhere((item) => item.id == roomId);
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() {
    return _repository.save(
      PropertySnapshot(properties: _properties, floors: _floors, rooms: _rooms),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
