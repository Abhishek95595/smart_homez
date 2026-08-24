import 'package:flutter/material.dart';

enum HomeLayoutTemplateType { studio, twoBhk, threeBhk, villa, custom }

enum HierarchyMode { flat, floorBased }

extension HomeLayoutTemplateTypeX on HomeLayoutTemplateType {
  String get id {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return 'Studio';
      case HomeLayoutTemplateType.twoBhk:
        return '2BHK';
      case HomeLayoutTemplateType.threeBhk:
        return '3BHK';
      case HomeLayoutTemplateType.villa:
        return 'Villa';
      case HomeLayoutTemplateType.custom:
        return 'Custom';
    }
  }

  String get title {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return 'Studio Apartment';
      case HomeLayoutTemplateType.twoBhk:
        return '2 BHK Apartment';
      case HomeLayoutTemplateType.threeBhk:
        return '3 BHK Apartment';
      case HomeLayoutTemplateType.villa:
        return 'Multi-Floor Villa';
      case HomeLayoutTemplateType.custom:
        return 'Custom Layout';
    }
  }

  String get description {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return 'Compact single-space layout with living/sleeping zone, kitchen & bath.';
      case HomeLayoutTemplateType.twoBhk:
        return 'Standard 2 bedroom setup with living room, kitchen, 2 baths & balcony.';
      case HomeLayoutTemplateType.threeBhk:
        return 'Spacious 3 bedroom home with living, dining, kitchen & multiple baths.';
      case HomeLayoutTemplateType.villa:
        return 'Multi-level home with Ground, First Floor and Rooftop spaces.';
      case HomeLayoutTemplateType.custom:
        return 'Design your own custom rooms and optional multi-floor structure.';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return Icons.weekend_outlined;
      case HomeLayoutTemplateType.twoBhk:
        return Icons.home_outlined;
      case HomeLayoutTemplateType.threeBhk:
        return Icons.apartment_outlined;
      case HomeLayoutTemplateType.villa:
        return Icons.villa_outlined;
      case HomeLayoutTemplateType.custom:
        return Icons.architecture_rounded;
    }
  }

  HierarchyMode get defaultHierarchyMode {
    switch (this) {
      case HomeLayoutTemplateType.studio:
      case HomeLayoutTemplateType.twoBhk:
      case HomeLayoutTemplateType.threeBhk:
        return HierarchyMode.flat;
      case HomeLayoutTemplateType.villa:
        return HierarchyMode.floorBased;
      case HomeLayoutTemplateType.custom:
        return HierarchyMode.flat;
    }
  }

  List<String> get defaultFlatRoomNames {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return const ['Living & Bedroom', 'Kitchenette', 'Bathroom'];
      case HomeLayoutTemplateType.twoBhk:
        return const [
          'Living Room',
          'Master Bedroom',
          'Bedroom 2',
          'Kitchen',
          'Master Bathroom',
          'Common Bathroom',
          'Balcony',
        ];
      case HomeLayoutTemplateType.threeBhk:
        return const [
          'Living Room',
          'Dining Room',
          'Master Bedroom',
          'Bedroom 2',
          'Bedroom 3',
          'Kitchen',
          'Master Bathroom',
          'Common Bathroom',
          'Balcony',
        ];
      case HomeLayoutTemplateType.villa:
        return const [];
      case HomeLayoutTemplateType.custom:
        return const ['Living Room', 'Master Bedroom', 'Kitchen'];
    }
  }

  List<CustomFloorDraft> get defaultVillaFloors {
    if (this != HomeLayoutTemplateType.villa) return const [];
    return [
      CustomFloorDraft(
        name: 'Ground Floor',
        level: 0,
        rooms: const [
          'Living Room',
          'Dining Area',
          'Kitchen',
          'Guest Bedroom',
          'Powder Room',
          'Garden / Patio',
        ],
      ),
      CustomFloorDraft(
        name: 'First Floor',
        level: 1,
        rooms: const [
          'Master Bedroom',
          'Bedroom 2',
          'Family Lounge',
          'Balcony',
          'Master Bathroom',
        ],
      ),
      CustomFloorDraft(
        name: 'Rooftop',
        level: 2,
        rooms: const ['Terrace Lounge', 'Utility Room'],
      ),
    ];
  }

  static HomeLayoutTemplateType fromString(String? value) {
    if (value == null) return HomeLayoutTemplateType.twoBhk;
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    switch (normalized) {
      case 'studio':
        return HomeLayoutTemplateType.studio;
      case '2bhk':
      case 'twobhk':
        return HomeLayoutTemplateType.twoBhk;
      case '3bhk':
      case 'threebhk':
        return HomeLayoutTemplateType.threeBhk;
      case 'villa':
        return HomeLayoutTemplateType.villa;
      case 'custom':
        return HomeLayoutTemplateType.custom;
      default:
        return HomeLayoutTemplateType.twoBhk;
    }
  }
}

class CustomFloorDraft {
  String name;
  int level;
  List<String> rooms;

  CustomFloorDraft({
    required this.name,
    required this.level,
    required List<String> rooms,
  }) : rooms = List.from(rooms);

  CustomFloorDraft copyWith({String? name, int? level, List<String>? rooms}) {
    return CustomFloorDraft(
      name: name ?? this.name,
      level: level ?? this.level,
      rooms: rooms != null ? List.from(rooms) : List.from(this.rooms),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'level': level,
    'rooms': rooms,
  };
}
