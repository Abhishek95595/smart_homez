import 'package:flutter/material.dart';

import '../data/home_setup_service.dart';
import '../data/models/bulk_assignment_models.dart';
import '../data/models/home_layout_template.dart';
import '../data/models/home_setup_request.dart';
import '../data/models/home_setup_response.dart';
import '../data/models/unassigned_device_model.dart';
import '../data/room_suggestion_service.dart';

class HomeSetupProvider extends ChangeNotifier {
  final HomeSetupService _setupService;
  final RoomSuggestionService _suggestionService;

  HomeSetupProvider({
    HomeSetupService? setupService,
    RoomSuggestionService? suggestionService,
  }) : _setupService = setupService ?? HomeSetupService(),
       _suggestionService = suggestionService ?? const RoomSuggestionService() {
    _initCustomDefaults();
  }

  // Wizard state
  int _currentStep = 0;
  HomeLayoutTemplateType _selectedTemplate = HomeLayoutTemplateType.twoBhk;
  HierarchyMode _hierarchyMode = HierarchyMode.flat;
  String _homeName = 'My Smart Home';
  String _address = '';

  // Custom draft rooms & floors
  List<String> _customFlatRooms = [];
  List<CustomFloorDraft> _customFloors = [];

  // Step 1 Output / Step 2 Input
  HomeSetupResult? _createdHome;

  // Step 2 State
  List<UnassignedDevice> _unassignedDevices = [];
  final Map<String, String?> _deviceAssignments = {}; // deviceId -> roomId?
  List<BulkAssignmentFailure> _partialFailures = [];

  // Loading & Error states
  bool _isLoading = false;
  bool _isFetchingDevices = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _deviceFetchError;
  bool _isCompleted = false;

  // Getters
  int get currentStep => _currentStep;
  HomeLayoutTemplateType get selectedTemplate => _selectedTemplate;
  HierarchyMode get hierarchyMode => _hierarchyMode;
  String get homeName => _homeName;
  String get address => _address;
  List<String> get customFlatRooms => List.unmodifiable(_customFlatRooms);
  List<CustomFloorDraft> get customFloors => List.unmodifiable(_customFloors);
  HomeSetupResult? get createdHome => _createdHome;
  List<UnassignedDevice> get unassignedDevices =>
      List.unmodifiable(_unassignedDevices);
  Map<String, String?> get deviceAssignments =>
      Map.unmodifiable(_deviceAssignments);
  List<BulkAssignmentFailure> get partialFailures =>
      List.unmodifiable(_partialFailures);

  bool get isLoading => _isLoading;
  bool get isFetchingDevices => _isFetchingDevices;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get deviceFetchError => _deviceFetchError;
  bool get isCompleted => _isCompleted;

  List<CreatedRoom> get availableRooms => _createdHome?.allRooms ?? [];

  int get assignedCount => _deviceAssignments.values
      .where((rId) => rId != null && rId.isNotEmpty)
      .length;

  int get totalDevicesCount => _unassignedDevices.length;

  void _initCustomDefaults() {
    _customFlatRooms = List.from(
      HomeLayoutTemplateType.custom.defaultFlatRoomNames,
    );
    _customFloors = [
      CustomFloorDraft(
        name: 'Ground Floor',
        level: 0,
        rooms: ['Living Room', 'Kitchen', 'Bathroom'],
      ),
      CustomFloorDraft(
        name: 'First Floor',
        level: 1,
        rooms: ['Master Bedroom', 'Bedroom 2', 'Balcony'],
      ),
    ];
  }

  void setStep(int step) {
    if (step == _currentStep) return;
    _currentStep = step;
    notifyListeners();
  }

  void setTemplate(HomeLayoutTemplateType template) {
    _selectedTemplate = template;
    _hierarchyMode = template.defaultHierarchyMode;
    _errorMessage = null;
    notifyListeners();
  }

  void setHierarchyMode(HierarchyMode mode) {
    _hierarchyMode = mode;
    notifyListeners();
  }

  void setHomeName(String name) {
    _homeName = name;
    notifyListeners();
  }

  void setAddress(String address) {
    _address = address;
    notifyListeners();
  }

  // ============================================================
  // CUSTOM FLAT ROOMS MANAGEMENT
  // ============================================================

  String? addCustomFlatRoom(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Room name cannot be empty.';
    final exists = _customFlatRooms.any(
      (r) => r.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return 'Room "$trimmed" already exists.';
    _customFlatRooms.add(trimmed);
    notifyListeners();
    return null;
  }

  String? renameCustomFlatRoom(int index, String newName) {
    if (index < 0 || index >= _customFlatRooms.length)
      return 'Invalid room index.';
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return 'Room name cannot be empty.';
    for (int i = 0; i < _customFlatRooms.length; i++) {
      if (i != index &&
          _customFlatRooms[i].trim().toLowerCase() == trimmed.toLowerCase()) {
        return 'Room "$trimmed" already exists.';
      }
    }
    _customFlatRooms[index] = trimmed;
    notifyListeners();
    return null;
  }

  void removeCustomFlatRoom(int index) {
    if (index >= 0 && index < _customFlatRooms.length) {
      _customFlatRooms.removeAt(index);
      notifyListeners();
    }
  }

  // ============================================================
  // CUSTOM FLOORS & NESTED ROOMS MANAGEMENT
  // ============================================================

  String? addCustomFloor(String name, int level) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Floor name cannot be empty.';
    final exists = _customFloors.any(
      (f) =>
          f.name.trim().toLowerCase() == trimmed.toLowerCase() ||
          f.level == level,
    );
    if (exists) return 'A floor with this name or level already exists.';
    _customFloors.add(
      CustomFloorDraft(name: trimmed, level: level, rooms: ['Living Room']),
    );
    _customFloors.sort((a, b) => a.level.compareTo(b.level));
    notifyListeners();
    return null;
  }

  String? renameCustomFloor(int index, String newName, int level) {
    if (index < 0 || index >= _customFloors.length)
      return 'Invalid floor index.';
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return 'Floor name cannot be empty.';
    for (int i = 0; i < _customFloors.length; i++) {
      if (i != index &&
          (_customFloors[i].name.trim().toLowerCase() ==
                  trimmed.toLowerCase() ||
              _customFloors[i].level == level)) {
        return 'A floor with this name or level already exists.';
      }
    }
    _customFloors[index].name = trimmed;
    _customFloors[index].level = level;
    _customFloors.sort((a, b) => a.level.compareTo(b.level));
    notifyListeners();
    return null;
  }

  void removeCustomFloor(int index) {
    if (index >= 0 && index < _customFloors.length) {
      _customFloors.removeAt(index);
      notifyListeners();
    }
  }

  String? addRoomToFloor(int floorIndex, String roomName) {
    if (floorIndex < 0 || floorIndex >= _customFloors.length) {
      return 'Invalid floor.';
    }
    final trimmed = roomName.trim();
    if (trimmed.isEmpty) return 'Room name cannot be empty.';
    final floor = _customFloors[floorIndex];
    if (floor.rooms.any(
      (r) => r.trim().toLowerCase() == trimmed.toLowerCase(),
    )) {
      return 'Room "$trimmed" already exists on ${floor.name}.';
    }
    floor.rooms.add(trimmed);
    notifyListeners();
    return null;
  }

  String? renameRoomInFloor(int floorIndex, int roomIndex, String newName) {
    if (floorIndex < 0 || floorIndex >= _customFloors.length) {
      return 'Invalid floor.';
    }
    final floor = _customFloors[floorIndex];
    if (roomIndex < 0 || roomIndex >= floor.rooms.length) {
      return 'Invalid room.';
    }
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return 'Room name cannot be empty.';
    for (int i = 0; i < floor.rooms.length; i++) {
      if (i != roomIndex &&
          floor.rooms[i].trim().toLowerCase() == trimmed.toLowerCase()) {
        return 'Room "$trimmed" already exists on ${floor.name}.';
      }
    }
    floor.rooms[roomIndex] = trimmed;
    notifyListeners();
    return null;
  }

  void removeRoomFromFloor(int floorIndex, int roomIndex) {
    if (floorIndex >= 0 && floorIndex < _customFloors.length) {
      final floor = _customFloors[floorIndex];
      if (roomIndex >= 0 && roomIndex < floor.rooms.length) {
        floor.rooms.removeAt(roomIndex);
        notifyListeners();
      }
    }
  }

  // ============================================================
  // VALIDATION & STEP 1 EXECUTION
  // ============================================================

  String? validateLayoutStep() {
    if (_homeName.trim().isEmpty) {
      return 'Please enter a home name.';
    }

    if (_selectedTemplate == HomeLayoutTemplateType.custom) {
      if (_hierarchyMode == HierarchyMode.flat) {
        if (_customFlatRooms.isEmpty) {
          return 'Please add at least one room to your custom layout.';
        }
        for (final room in _customFlatRooms) {
          if (room.trim().isEmpty) {
            return 'Room names cannot be empty.';
          }
        }
      } else {
        if (_customFloors.isEmpty) {
          return 'Please add at least one floor to your custom layout.';
        }
        for (final floor in _customFloors) {
          if (floor.name.trim().isEmpty) {
            return 'Floor names cannot be empty.';
          }
          if (floor.rooms.isEmpty) {
            return 'Floor "${floor.name}" must contain at least one room.';
          }
          for (final room in floor.rooms) {
            if (room.trim().isEmpty) {
              return 'Room names cannot be empty.';
            }
          }
        }
      }
    }

    return null;
  }

  HomeSetupRequest buildSetupRequest() {
    List<String>? flatRooms;
    List<CustomFloorDraft>? floors;

    if (_selectedTemplate == HomeLayoutTemplateType.custom) {
      if (_hierarchyMode == HierarchyMode.flat) {
        flatRooms = List.from(_customFlatRooms);
      } else {
        floors = List.from(_customFloors);
      }
    } else if (_selectedTemplate == HomeLayoutTemplateType.villa) {
      floors = List.from(_selectedTemplate.defaultVillaFloors);
    } else {
      flatRooms = List.from(_selectedTemplate.defaultFlatRoomNames);
    }

    return HomeSetupRequest(
      template: _selectedTemplate.id,
      homeName: _homeName.trim(),
      address: _address.trim().isEmpty ? null : _address.trim(),
      hierarchyMode: _hierarchyMode,
      flatRooms: flatRooms,
      floors: floors,
    );
  }

  Future<bool> createHomeLayout({required bool canManage}) async {
    if (!canManage) {
      _errorMessage = 'You do not have permission to create home layouts.';
      notifyListeners();
      return false;
    }

    final validationError = validateLayoutStep();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = buildSetupRequest();
      _createdHome = await _setupService.setupHomeFromTemplate(request);

      _isLoading = false;
      _currentStep = 1; // Transition to Step 2
      notifyListeners();

      // Automatically fetch unassigned devices for step 2
      await fetchUnassignedDevices();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // STEP 2: DEVICE ASSIGNMENT
  // ============================================================

  Future<void> fetchUnassignedDevices() async {
    if (_createdHome == null) return;

    _isFetchingDevices = true;
    _deviceFetchError = null;
    notifyListeners();

    try {
      _unassignedDevices = await _setupService.getUnassignedDevices(
        _createdHome!.home.id,
      );
      _deviceAssignments.clear();

      final rooms = availableRooms;

      // Initialize assignments using suggestion service
      for (final device in _unassignedDevices) {
        final suggestedRoomId = _suggestionService.resolveSuggestedRoomId(
          device: device,
          availableRooms: rooms,
        );
        _deviceAssignments[device.id] = suggestedRoomId;
      }
    } catch (e) {
      _deviceFetchError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[HomeSetupProvider] Device fetch error: $e');
    } finally {
      _isFetchingDevices = false;
      notifyListeners();
    }
  }

  void assignDevice(String deviceId, String? roomId) {
    _deviceAssignments[deviceId] = roomId;
    _partialFailures.removeWhere((f) => f.deviceId == deviceId);
    notifyListeners();
  }

  void assignAllSuggested() {
    final rooms = availableRooms;
    for (final device in _unassignedDevices) {
      final suggestedRoomId = _suggestionService.resolveSuggestedRoomId(
        device: device,
        availableRooms: rooms,
      );
      if (suggestedRoomId != null) {
        _deviceAssignments[device.id] = suggestedRoomId;
      }
    }
    notifyListeners();
  }

  void clearAllAssignments() {
    for (final device in _unassignedDevices) {
      _deviceAssignments[device.id] = null;
    }
    notifyListeners();
  }

  Future<bool> submitAssignments({required bool canManage}) async {
    if (!canManage) {
      _errorMessage = 'You do not have permission to assign devices.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _partialFailures.clear();
    notifyListeners();

    try {
      final List<DeviceAssignmentItem> assignments = [];
      _deviceAssignments.forEach((deviceId, roomId) {
        if (roomId != null && roomId.isNotEmpty) {
          assignments.add(
            DeviceAssignmentItem(deviceId: deviceId, roomId: roomId),
          );
        }
      });

      final response = await _setupService.bulkAssignDevicesToRooms(
        assignments,
      );

      if (response.hasFailures) {
        _partialFailures = List.from(response.failedAssignments);
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      _isCompleted = true;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> retryFailedAssignments({required bool canManage}) async {
    if (_partialFailures.isEmpty) return true;

    final failedIds = _partialFailures.map((f) => f.deviceId).toSet();
    final List<DeviceAssignmentItem> retryItems = [];

    _deviceAssignments.forEach((deviceId, roomId) {
      if (failedIds.contains(deviceId) && roomId != null && roomId.isNotEmpty) {
        retryItems.add(
          DeviceAssignmentItem(deviceId: deviceId, roomId: roomId),
        );
      }
    });

    if (retryItems.isEmpty) {
      _partialFailures.clear();
      notifyListeners();
      return true;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await _setupService.bulkAssignDevicesToRooms(retryItems);
      _partialFailures = List.from(response.failedAssignments);
      _isSubmitting = false;

      if (_partialFailures.isEmpty) {
        _isCompleted = true;
        notifyListeners();
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _currentStep = 0;
    _selectedTemplate = HomeLayoutTemplateType.twoBhk;
    _hierarchyMode = HierarchyMode.flat;
    _homeName = 'My Smart Home';
    _address = '';
    _createdHome = null;
    _unassignedDevices = [];
    _deviceAssignments.clear();
    _partialFailures.clear();
    _isLoading = false;
    _isFetchingDevices = false;
    _isSubmitting = false;
    _errorMessage = null;
    _deviceFetchError = null;
    _isCompleted = false;
    _initCustomDefaults();
    notifyListeners();
  }
}
