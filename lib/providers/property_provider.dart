import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/property_hierarchy.dart';
import '../services/property_repository.dart';
import '../services/tenant_api_repository.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  final TenantApiRepository _apiRepo = TenantApiRepository();
  final Uuid _uuid;
  final List<ManagedProperty> _properties = [];
  final List<ManagedFloor> _floors = [];
  final List<ManagedRoom> _rooms = [];

  bool _isLoading = true;
  bool _isDisposed = false;
  String? _loadError;
  String? _clientId; // From AuthProvider

  PropertyProvider({PropertyRepository? repository, Uuid uuid = const Uuid()})
    : _repository = repository ?? HivePropertyRepository(),
      _uuid = uuid {
    _load();
  }

  void setClientId(String? id) {
    _clientId = id;
  }

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
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
    if (_properties.isNotEmpty) return;
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
    _floors.addAll(const [
      ManagedFloor(
        id: 'floor_3',
        propertyId: 'bldg_A',
        name: 'Floor 3',
        level: 3,
      ),
      ManagedFloor(
        id: 'floor_4',
        propertyId: 'bldg_A',
        name: 'Floor 4',
        level: 4,
      ),
      ManagedFloor(
        id: 'palm_floor_1',
        propertyId: 'bldg_B',
        name: 'Floor 1',
        level: 1,
      ),
      ManagedFloor(
        id: 'palm_floor_2',
        propertyId: 'bldg_B',
        name: 'Floor 2',
        level: 2,
      ),
    ]);
    _rooms.addAll(const [
      ManagedRoom(
        id: 'room_302_living',
        floorId: 'floor_3',
        name: 'Living Room',
        type: 'Living Room',
      ),
      ManagedRoom(
        id: 'room_302_bedroom',
        floorId: 'floor_3',
        name: 'Bedroom',
        type: 'Bedroom',
      ),
      ManagedRoom(
        id: 'room_302_kitchen',
        floorId: 'floor_3',
        name: 'Kitchen',
        type: 'Kitchen',
      ),
      ManagedRoom(
        id: 'room_501_living',
        floorId: 'palm_floor_1',
        name: 'Living Room',
        type: 'Living Room',
      ),
      ManagedRoom(
        id: 'room_601_bedroom',
        floorId: 'palm_floor_2',
        name: 'Bedroom',
        type: 'Bedroom',
      ),
    ]);
  }

  Future<void> syncFromApi(String clientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiHomes = await _apiRepo.getHomes(clientId);
      if (apiHomes.isNotEmpty) {
        _properties.clear();
        _floors.clear();
        _rooms.clear();

        for (final h in apiHomes) {
          _properties.add(ManagedProperty(
            id: h.id,
            name: h.name,
            address: h.address,
          ));

          final apiFloors = await _apiRepo.getFloors(clientId, h.id);
          for (final f in apiFloors) {
            _floors.add(ManagedFloor(
              id: f.id,
              propertyId: h.id,
              name: f.name,
              level: f.floorNumber,
            ));

            final apiRooms = await _apiRepo.getRooms(clientId, h.id, f.id);
            for (final r in apiRooms) {
              _rooms.add(ManagedRoom(
                id: r.id,
                floorId: f.id,
                name: r.name,
                type: 'Other',
              ));
            }
          }
        }
        await _save();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
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

  bool roomNameExists(String floorId, String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _rooms.any(
      (item) =>
          item.id != excludingId &&
          item.floorId == floorId &&
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
    
    String finalId = _uuid.v4();

    // API Integration
    if (_clientId != null) {
      final apiResponse = await _apiRepo.createHome(
        _clientId!,
        name: resolvedName,
        address: address.trim(),
      );
      if (apiResponse != null) {
        finalId = apiResponse.id;
      }
    }

    final item = ManagedProperty(
      id: finalId,
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
    final floorIds = floorsFor(propertyId).map((item) => item.id).toSet();
    _rooms.removeWhere((item) => floorIds.contains(item.floorId));
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
    String finalId = _uuid.v4();

    // API Integration
    if (_clientId != null) {
      final apiResponse = await _apiRepo.createFloor(
        _clientId!,
        propertyId,
        name: resolvedName,
        floorNumber: level,
      );
      if (apiResponse != null) {
        finalId = apiResponse.id;
      }
    }

    final item = ManagedFloor(
      id: finalId,
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
    _floors[index] = floor.copyWith(
      name: name.trim().isEmpty ? floor.name : name.trim(),
      level: level,
    );
    await _saveAndNotify();
  }

  Future<void> deleteFloor(String floorId) async {
    _rooms.removeWhere((item) => item.floorId == floorId);
    _floors.removeWhere((item) => item.id == floorId);
    await _saveAndNotify();
  }

  Future<ManagedRoom> addRoom({
    required String floorId,
    required String name,
    required String type,
  }) async {
    final enteredName = name.trim();
    final baseName = type.trim().isEmpty ? 'Room' : type.trim();
    final resolvedName = enteredName.isEmpty
        ? _nextAvailableName(
            baseName,
            _rooms
                .where((room) => room.floorId == floorId)
                .map((room) => room.name),
          )
        : enteredName;

    String finalId = _uuid.v4();

    // API Integration - Finding propertyId for this floor
    final floor = floorById(floorId);
    if (_clientId != null && floor != null) {
      final apiResponse = await _apiRepo.createRoom(
        _clientId!,
        floor.propertyId,
        floorId,
        name: resolvedName,
      );
      if (apiResponse != null) {
        finalId = apiResponse.id;
      }
    }

    final item = ManagedRoom(
      id: finalId,
      floorId: floorId,
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
  }) async {
    final index = _rooms.indexWhere((item) => item.id == room.id);
    if (index == -1) return;
    _rooms[index] = room.copyWith(
      name: name.trim().isEmpty ? room.name : name.trim(),
      type: type,
    );
    await _saveAndNotify();
  }

  Future<void> deleteRoom(String roomId) async {
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
