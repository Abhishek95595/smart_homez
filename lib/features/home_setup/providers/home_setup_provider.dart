import 'package:flutter/material.dart';

import '../../../models/property_hierarchy.dart';
import '../../../providers/property_provider.dart';
import '../data/home_setup_service.dart';
import '../data/models/home_layout_template.dart';
import '../data/models/home_setup_request.dart';
import '../data/models/home_setup_response.dart';
import '../data/models/property_setup_draft.dart';

class HomeSetupProvider extends ChangeNotifier {
  final HomeSetupService _setupService;

  HomeSetupProvider({HomeSetupService? setupService})
    : _setupService = setupService ?? HomeSetupService() {
    _initDefaults();
  }

  // Wizard state
  int _currentStep = 0; // 0: Property, 1: Layout, 2: Rooms, 3: Review
  PropertyCategory _category = PropertyCategory.residential;
  String _propertyName = '';
  String _address = '';

  HomeLayoutTemplateType _selectedTemplate = HomeLayoutTemplateType.twoBhk;
  int _floorCount = 1;

  // Draft floors & rooms state
  List<DraftRoom> _draftRooms = [];
  List<DraftFloor> _draftFloors = [];

  // Creation output
  HomeSetupResult? _createdHome;
  ManagedProperty? _createdProperty;

  // Loading & Error states
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isCompleted = false;

  // Getters
  int get currentStep => _currentStep;
  PropertyCategory get category => _category;
  String get propertyName => _propertyName;
  String get address => _address;
  HomeLayoutTemplateType get selectedTemplate => _selectedTemplate;
  int get floorCount => _floorCount;

  List<DraftRoom> get draftRooms => List.unmodifiable(_draftRooms);
  List<DraftFloor> get draftFloors => List.unmodifiable(_draftFloors);

  HomeSetupResult? get createdHome => _createdHome;
  ManagedProperty? get createdProperty => _createdProperty;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isCompleted => _isCompleted;

  bool get isMultiFloor => _selectedTemplate.isMultiFloor;

  int get totalRoomCount {
    if (isMultiFloor) {
      return _draftFloors.fold(0, (sum, f) => sum + f.rooms.length);
    }
    return _draftRooms.length;
  }

  void _initDefaults() {
    _category = PropertyCategory.residential;
    _selectedTemplate = HomeLayoutTemplateType.twoBhk;
    _floorCount = _selectedTemplate.defaultFloorCount;
    _initStructureForTemplate(_selectedTemplate);
  }

  void _initStructureForTemplate(HomeLayoutTemplateType template) {
    if (template.isMultiFloor) {
      _draftFloors = template.generateDefaultFloors(_floorCount);
      _draftRooms = [];
    } else {
      _draftFloors = [];
      _draftRooms = template.defaultFlatRoomNames
          .map((name) => DraftRoom(name: name))
          .toList();
    }
  }

  void setStep(int step) {
    if (step < 0 || step > 3 || step == _currentStep) return;
    _currentStep = step;
    notifyListeners();
  }

  void goNext() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  void goBack() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setCategory(PropertyCategory newCategory) {
    if (_category == newCategory) return;
    _category = newCategory;

    // Reset template, floors, rooms while preserving propertyName and address
    if (_category == PropertyCategory.residential) {
      _selectedTemplate = HomeLayoutTemplateType.twoBhk;
    } else {
      _selectedTemplate = HomeLayoutTemplateType.office;
    }
    _floorCount = _selectedTemplate.defaultFloorCount;
    _initStructureForTemplate(_selectedTemplate);

    notifyListeners();
  }

  void setPropertyName(String name) {
    if (_propertyName == name) return;
    _propertyName = name;
    _errorMessage = null;
    notifyListeners();
  }

  void setAddress(String addr) {
    if (_address == addr) return;
    _address = addr;
    notifyListeners();
  }

  void selectTemplate(HomeLayoutTemplateType template) {
    _selectedTemplate = template;
    _floorCount = template.defaultFloorCount;
    _initStructureForTemplate(template);
    _errorMessage = null;
    notifyListeners();
  }

  void setFloorCount(int count) {
    if (!isMultiFloor) return;
    final min = _selectedTemplate.minFloorCount;
    final max = _selectedTemplate.maxFloorCount;
    final target = count.clamp(min, max);
    if (target == _floorCount) return;

    if (target > _floorCount) {
      // Increase floor count: preserve existing floors and rooms, generate ONLY new floors
      final currentList = List<DraftFloor>.from(_draftFloors);
      for (int i = _floorCount; i < target; i++) {
        String floorName;
        if (i == 1) {
          floorName = '1st Floor';
        } else if (i == 2) {
          floorName = '2nd Floor';
        } else {
          floorName = '${i}th Floor';
        }
        final roomNames = ['Room ${i}01', 'Room ${i}02', 'Bathroom'];
        currentList.add(
          DraftFloor(
            name: floorName,
            level: i,
            rooms: roomNames.map((r) => DraftRoom(name: r)).toList(),
          ),
        );
      }
      _draftFloors = currentList;
    } else {
      // Decrease floor count: remove ONLY the highest floor(s)
      _draftFloors = _draftFloors.sublist(0, target);
    }

    _floorCount = target;
    notifyListeners();
  }

  void increaseFloorCount() {
    setFloorCount(_floorCount + 1);
  }

  void decreaseFloorCount() {
    setFloorCount(_floorCount - 1);
  }

  void addRoom(String roomName, {String? floorLocalId}) {
    final trimmed = roomName.trim();
    if (trimmed.isEmpty) return;

    if (isMultiFloor) {
      if (floorLocalId == null && _draftFloors.isNotEmpty) {
        floorLocalId = _draftFloors.first.localId;
      }
      _draftFloors = _draftFloors.map((floor) {
        if (floor.localId == floorLocalId) {
          final updatedRooms = List<DraftRoom>.from(floor.rooms)
            ..add(DraftRoom(name: trimmed, userAdded: true));
          return floor.copyWith(rooms: updatedRooms);
        }
        return floor;
      }).toList();
    } else {
      _draftRooms = List<DraftRoom>.from(_draftRooms)
        ..add(DraftRoom(name: trimmed, userAdded: true));
    }
    notifyListeners();
  }

  void deleteRoom(String roomLocalId, {String? floorLocalId}) {
    if (isMultiFloor) {
      _draftFloors = _draftFloors.map((floor) {
        if (floorLocalId == null || floor.localId == floorLocalId) {
          final updatedRooms = floor.rooms
              .where((r) => r.localId != roomLocalId)
              .toList();
          return floor.copyWith(rooms: updatedRooms);
        }
        return floor;
      }).toList();
    } else {
      _draftRooms = _draftRooms.where((r) => r.localId != roomLocalId).toList();
    }
    notifyListeners();
  }

  Future<bool> submitPropertyCreation({
    required PropertyProvider propertyProvider,
  }) async {
    if (_isSubmitting) return false;
    if (_propertyName.trim().isEmpty) {
      _errorMessage = 'Property name is required.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final flatRoomNames = !isMultiFloor
          ? _draftRooms.map((r) => r.name).toList()
          : null;

      final customFloors = isMultiFloor
          ? _draftFloors
                .map(
                  (f) => CustomFloorDraft(
                    name: f.name,
                    level: f.level,
                    rooms: f.rooms.map((r) => r.name).toList(),
                  ),
                )
                .toList()
          : null;

      final request = HomeSetupRequest(
        template: _selectedTemplate.id,
        homeName: _propertyName.trim(),
        address: _address.trim().isNotEmpty ? _address.trim() : null,
        hierarchyMode: isMultiFloor
            ? HierarchyMode.floorBased
            : HierarchyMode.flat,
        flatRooms: flatRoomNames,
        floors: customFloors,
      );

      // Submit via backend setup service
      final result = await _setupService.setupHomeFromTemplate(request);
      _createdHome = result;

      // Refresh property provider state
      await propertyProvider.reload();
      if (result.home.id.isNotEmpty) {
        _createdProperty =
            propertyProvider.propertyById(result.home.id) ??
            ManagedProperty(
              id: result.home.id,
              name: result.home.name,
              category: _category == PropertyCategory.residential
                  ? 'Residential'
                  : 'Commercial',
              propertyType: _selectedTemplate.title,
              address: _address.trim(),
            );
      }

      _isSubmitting = false;
      _isCompleted = true;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback: Create locally via PropertyProvider if offline/demo
      try {
        final newProp = await propertyProvider.addProperty(
          name: _propertyName.trim(),
          address: _address.trim(),
          category: _category == PropertyCategory.residential
              ? 'Residential'
              : 'Commercial',
          propertyType: _selectedTemplate.title,
        );

        if (isMultiFloor) {
          for (final f in _draftFloors) {
            final newFloor = await propertyProvider.addFloor(
              propertyId: newProp.id,
              name: f.name,
              level: f.level,
            );
            for (final r in f.rooms) {
              await propertyProvider.addRoom(
                homeId: newProp.id,
                floorId: newFloor.id,
                name: r.name,
                type: 'Room',
              );
            }
          }
        } else {
          for (final r in _draftRooms) {
            await propertyProvider.addRoom(
              homeId: newProp.id,
              name: r.name,
              type: 'Room',
            );
          }
        }

        _createdProperty = newProp;
        _isSubmitting = false;
        _isCompleted = true;
        notifyListeners();
        return true;
      } catch (err) {
        _isSubmitting = false;
        _errorMessage = 'Failed to create property: $err';
        notifyListeners();
        return false;
      }
    }
  }

  void reset() {
    _currentStep = 0;
    _propertyName = '';
    _address = '';
    _isSubmitting = false;
    _errorMessage = null;
    _isCompleted = false;
    _createdHome = null;
    _createdProperty = null;
    _initDefaults();
    notifyListeners();
  }
}
