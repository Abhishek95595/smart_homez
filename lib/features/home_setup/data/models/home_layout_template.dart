import 'package:flutter/material.dart';
import 'property_setup_draft.dart';

enum PropertyCategory { residential, commercial }

enum HomeLayoutTemplateType {
  // Residential
  studio,
  oneBhk,
  twoBhk,
  threeBhk,
  fourBhk,
  independentHouse,
  villa,
  pgHostel,
  custom,

  // Commercial
  office,
  retailStore,
  warehouse,
  coworkingSpace,
  restaurant,
  hotel,
  clinic,
  school,
  factory,
  customCommercial,
}

enum HierarchyMode { flat, floorBased }

extension HomeLayoutTemplateTypeX on HomeLayoutTemplateType {
  PropertyCategory get category {
    switch (this) {
      case HomeLayoutTemplateType.studio:
      case HomeLayoutTemplateType.oneBhk:
      case HomeLayoutTemplateType.twoBhk:
      case HomeLayoutTemplateType.threeBhk:
      case HomeLayoutTemplateType.fourBhk:
      case HomeLayoutTemplateType.independentHouse:
      case HomeLayoutTemplateType.villa:
      case HomeLayoutTemplateType.pgHostel:
      case HomeLayoutTemplateType.custom:
        return PropertyCategory.residential;

      case HomeLayoutTemplateType.office:
      case HomeLayoutTemplateType.retailStore:
      case HomeLayoutTemplateType.warehouse:
      case HomeLayoutTemplateType.coworkingSpace:
      case HomeLayoutTemplateType.restaurant:
      case HomeLayoutTemplateType.hotel:
      case HomeLayoutTemplateType.clinic:
      case HomeLayoutTemplateType.school:
      case HomeLayoutTemplateType.factory:
      case HomeLayoutTemplateType.customCommercial:
        return PropertyCategory.commercial;
    }
  }

  String get id => name;

  String get title {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return 'Studio Apartment';
      case HomeLayoutTemplateType.oneBhk:
        return '1 BHK Apartment';
      case HomeLayoutTemplateType.twoBhk:
        return '2 BHK Apartment';
      case HomeLayoutTemplateType.threeBhk:
        return '3 BHK Apartment';
      case HomeLayoutTemplateType.fourBhk:
        return '4+ BHK Apartment';
      case HomeLayoutTemplateType.independentHouse:
        return 'Independent House';
      case HomeLayoutTemplateType.villa:
        return 'Villa / Duplex';
      case HomeLayoutTemplateType.pgHostel:
        return 'PG / Hostel';
      case HomeLayoutTemplateType.custom:
        return 'Other / Create my own';

      case HomeLayoutTemplateType.office:
        return 'Office';
      case HomeLayoutTemplateType.retailStore:
        return 'Retail Store';
      case HomeLayoutTemplateType.warehouse:
        return 'Warehouse';
      case HomeLayoutTemplateType.coworkingSpace:
        return 'Co-working Space';
      case HomeLayoutTemplateType.restaurant:
        return 'Restaurant / Café';
      case HomeLayoutTemplateType.hotel:
        return 'Hotel / Guest House';
      case HomeLayoutTemplateType.clinic:
        return 'Clinic / Hospital';
      case HomeLayoutTemplateType.school:
        return 'School / Institute';
      case HomeLayoutTemplateType.factory:
        return 'Factory / Industrial';
      case HomeLayoutTemplateType.customCommercial:
        return 'Other / Create my own';
    }
  }

  String get description {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return 'Compact single-space layout with living/sleeping zone, kitchen & bath.';
      case HomeLayoutTemplateType.oneBhk:
        return 'Standard 1 bedroom setup with living room, kitchen, bath & balcony.';
      case HomeLayoutTemplateType.twoBhk:
        return 'Standard 2 bedroom setup with living room, kitchen, 2 baths & balcony.';
      case HomeLayoutTemplateType.threeBhk:
        return 'Spacious 3 bedroom home with living, dining, kitchen & multiple baths.';
      case HomeLayoutTemplateType.fourBhk:
        return 'Large 4 bedroom residence with living, dining, kitchen & 3 baths.';
      case HomeLayoutTemplateType.independentHouse:
        return 'Multi-level home with ground floor and upper living spaces.';
      case HomeLayoutTemplateType.villa:
        return 'Luxury multi-level villa with living, dining, bedrooms & terrace.';
      case HomeLayoutTemplateType.pgHostel:
        return 'Shared living space with common areas and multiple rooms.';
      case HomeLayoutTemplateType.custom:
        return 'Design your own custom layout from scratch.';

      case HomeLayoutTemplateType.office:
        return 'Corporate office setup with reception, workspace, cabins & meeting rooms.';
      case HomeLayoutTemplateType.retailStore:
        return 'Retail layout with sales floor, checkout, store room & office.';
      case HomeLayoutTemplateType.warehouse:
        return 'Industrial storage space with loading bays, zones & security office.';
      case HomeLayoutTemplateType.coworkingSpace:
        return 'Shared workspace with hot desks, private cabins, meeting rooms & lounge.';
      case HomeLayoutTemplateType.restaurant:
        return 'Food service establishment with dining area, kitchen, counter & wash space.';
      case HomeLayoutTemplateType.hotel:
        return 'Multi-level accommodation with reception, guest rooms & amenities.';
      case HomeLayoutTemplateType.clinic:
        return 'Healthcare facility with waiting area, consultation rooms & pharmacy.';
      case HomeLayoutTemplateType.school:
        return 'Educational institute layout with reception, classrooms & labs.';
      case HomeLayoutTemplateType.factory:
        return 'Manufacturing facility with production areas, storage & office.';
      case HomeLayoutTemplateType.customCommercial:
        return 'Design your own custom commercial property from scratch.';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return Icons.weekend_outlined;
      case HomeLayoutTemplateType.oneBhk:
      case HomeLayoutTemplateType.twoBhk:
      case HomeLayoutTemplateType.threeBhk:
      case HomeLayoutTemplateType.fourBhk:
        return Icons.apartment_outlined;
      case HomeLayoutTemplateType.independentHouse:
        return Icons.home_outlined;
      case HomeLayoutTemplateType.villa:
        return Icons.villa_outlined;
      case HomeLayoutTemplateType.pgHostel:
        return Icons.groups_outlined;
      case HomeLayoutTemplateType.custom:
      case HomeLayoutTemplateType.customCommercial:
        return Icons.architecture_rounded;

      case HomeLayoutTemplateType.office:
      case HomeLayoutTemplateType.coworkingSpace:
        return Icons.business_center_outlined;
      case HomeLayoutTemplateType.retailStore:
        return Icons.storefront_outlined;
      case HomeLayoutTemplateType.warehouse:
      case HomeLayoutTemplateType.factory:
        return Icons.warehouse_outlined;
      case HomeLayoutTemplateType.restaurant:
        return Icons.restaurant_outlined;
      case HomeLayoutTemplateType.hotel:
        return Icons.hotel_outlined;
      case HomeLayoutTemplateType.clinic:
        return Icons.local_hospital_outlined;
      case HomeLayoutTemplateType.school:
        return Icons.school_outlined;
    }
  }

  bool get isPopular {
    return this == HomeLayoutTemplateType.twoBhk ||
        this == HomeLayoutTemplateType.office;
  }

  bool get isMultiFloor {
    switch (this) {
      case HomeLayoutTemplateType.independentHouse:
      case HomeLayoutTemplateType.villa:
      case HomeLayoutTemplateType.pgHostel:
      case HomeLayoutTemplateType.hotel:
      case HomeLayoutTemplateType.school:
        return true;
      default:
        return false;
    }
  }

  int get minFloorCount {
    if (!isMultiFloor) return 1;
    if (this == HomeLayoutTemplateType.villa) return 2;
    return 1;
  }

  int get defaultFloorCount {
    if (!isMultiFloor) return 1;
    if (this == HomeLayoutTemplateType.hotel) return 3;
    return 2;
  }

  int get maxFloorCount => 20;

  HierarchyMode get defaultHierarchyMode =>
      isMultiFloor ? HierarchyMode.floorBased : HierarchyMode.flat;

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

  List<String> get defaultFlatRoomNames {
    switch (this) {
      case HomeLayoutTemplateType.studio:
        return const ['Living & Sleeping Area', 'Kitchenette', 'Bathroom'];
      case HomeLayoutTemplateType.oneBhk:
        return const [
          'Bedroom',
          'Living Room',
          'Kitchen',
          'Bathroom',
          'Balcony',
        ];
      case HomeLayoutTemplateType.twoBhk:
        return const [
          'Bedroom 1',
          'Bedroom 2',
          'Living Room',
          'Kitchen',
          'Bathroom 1',
          'Bathroom 2',
          'Balcony',
        ];
      case HomeLayoutTemplateType.threeBhk:
        return const [
          'Bedroom 1',
          'Bedroom 2',
          'Bedroom 3',
          'Living Room',
          'Dining Room',
          'Kitchen',
          'Bathroom 1',
          'Bathroom 2',
          'Balcony',
        ];
      case HomeLayoutTemplateType.fourBhk:
        return const [
          'Bedroom 1',
          'Bedroom 2',
          'Bedroom 3',
          'Bedroom 4',
          'Living Room',
          'Dining Room',
          'Kitchen',
          'Bathroom 1',
          'Bathroom 2',
          'Bathroom 3',
          'Balcony',
        ];

      case HomeLayoutTemplateType.office:
        return const [
          'Reception',
          'Workspace',
          'Cabin 1',
          'Meeting Room',
          'Pantry',
          'Server Room',
          'Restroom',
        ];
      case HomeLayoutTemplateType.retailStore:
        return const [
          'Sales Floor',
          'Checkout',
          'Store Room',
          'Office',
          'Restroom',
        ];
      case HomeLayoutTemplateType.warehouse:
        return const [
          'Loading Bay',
          'Storage Zone A',
          'Storage Zone B',
          'Office',
          'Security Room',
          'Restroom',
        ];
      case HomeLayoutTemplateType.coworkingSpace:
        return const [
          'Reception',
          'Hot Desk Area',
          'Private Cabin 1',
          'Private Cabin 2',
          'Meeting Room',
          'Lounge',
          'Pantry',
        ];
      case HomeLayoutTemplateType.restaurant:
        return const [
          'Dining Area',
          'Kitchen',
          'Counter',
          'Storage',
          'Wash Area',
          'Restroom',
        ];
      case HomeLayoutTemplateType.clinic:
        return const [
          'Reception',
          'Waiting Area',
          'Consultation Room 1',
          'Consultation Room 2',
          'Pharmacy',
          'Utility Room',
          'Restroom',
        ];
      case HomeLayoutTemplateType.factory:
        return const [
          'Production Area',
          'Storage',
          'Office',
          'Utility Room',
          'Security Room',
          'Restroom',
        ];

      case HomeLayoutTemplateType.custom:
      case HomeLayoutTemplateType.customCommercial:
      case HomeLayoutTemplateType.independentHouse:
      case HomeLayoutTemplateType.villa:
      case HomeLayoutTemplateType.pgHostel:
      case HomeLayoutTemplateType.hotel:
      case HomeLayoutTemplateType.school:
        return const [];
    }
  }

  List<DraftFloor> generateDefaultFloors(int count) {
    if (!isMultiFloor) return const [];
    final List<DraftFloor> result = [];

    for (int i = 0; i < count; i++) {
      String floorName;
      if (i == 0) {
        floorName = 'Ground Floor';
      } else if (i == count - 1 &&
          count >= 3 &&
          (this == HomeLayoutTemplateType.villa ||
              this == HomeLayoutTemplateType.independentHouse)) {
        floorName = 'Terrace / Rooftop';
      } else if (i == 1) {
        floorName = '1st Floor';
      } else if (i == 2) {
        floorName = '2nd Floor';
      } else {
        floorName = '${i}th Floor';
      }

      List<String> roomNames = [];
      if (this == HomeLayoutTemplateType.villa ||
          this == HomeLayoutTemplateType.independentHouse) {
        if (i == 0) {
          roomNames = const [
            'Living Room',
            'Dining Room',
            'Kitchen',
            'Guest Bedroom',
            'Guest Bathroom',
            'Entrance / Foyer',
          ];
        } else if (i == 1) {
          roomNames = const [
            'Master Bedroom',
            'Bedroom 2',
            'Family Lounge',
            'Balcony',
            'Master Bathroom',
          ];
        } else if (floorName.contains('Terrace') ||
            floorName.contains('Rooftop')) {
          roomNames = const ['Terrace Lounge', 'Utility Room'];
        } else {
          roomNames = [
            'Bedroom ${i + 1}',
            'Study / Office',
            'Bathroom',
            'Balcony',
          ];
        }
      } else if (this == HomeLayoutTemplateType.hotel) {
        if (i == 0) {
          roomNames = const [
            'Reception & Lobby',
            'Restaurant / Dining',
            'Kitchen',
            'Utility & Storage',
            'Restroom',
          ];
        } else {
          roomNames = [
            'Guest Room ${i}01',
            'Guest Room ${i}02',
            'Guest Room ${i}03',
            'Housekeeping Station',
          ];
        }
      } else if (this == HomeLayoutTemplateType.school) {
        if (i == 0) {
          roomNames = const [
            'Reception & Admin Office',
            'Principal Office',
            'Classroom 101',
            'Classroom 102',
            'Staff Room',
            'Restroom',
          ];
        } else {
          roomNames = [
            'Classroom ${i}01',
            'Classroom ${i}02',
            'Science / Computer Lab',
            'Restroom',
          ];
        }
      } else if (this == HomeLayoutTemplateType.pgHostel) {
        if (i == 0) {
          roomNames = const [
            'Reception',
            'Common Lounge',
            'Kitchen & Mess',
            'Room 101',
            'Shared Bathroom',
          ];
        } else {
          roomNames = [
            'Room ${i}01',
            'Room ${i}02',
            'Room ${i}03',
            'Shared Bathroom',
          ];
        }
      }

      result.add(
        DraftFloor(
          name: floorName,
          level: i,
          rooms: roomNames.map((r) => DraftRoom(name: r)).toList(),
        ),
      );
    }

    return result;
  }

  static List<HomeLayoutTemplateType> getResidentialTemplates() {
    return const [
      HomeLayoutTemplateType.studio,
      HomeLayoutTemplateType.oneBhk,
      HomeLayoutTemplateType.twoBhk,
      HomeLayoutTemplateType.threeBhk,
      HomeLayoutTemplateType.fourBhk,
      HomeLayoutTemplateType.independentHouse,
      HomeLayoutTemplateType.villa,
      HomeLayoutTemplateType.pgHostel,
      HomeLayoutTemplateType.custom,
    ];
  }

  static List<HomeLayoutTemplateType> getCommercialTemplates() {
    return const [
      HomeLayoutTemplateType.office,
      HomeLayoutTemplateType.retailStore,
      HomeLayoutTemplateType.warehouse,
      HomeLayoutTemplateType.coworkingSpace,
      HomeLayoutTemplateType.restaurant,
      HomeLayoutTemplateType.hotel,
      HomeLayoutTemplateType.clinic,
      HomeLayoutTemplateType.school,
      HomeLayoutTemplateType.factory,
      HomeLayoutTemplateType.customCommercial,
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
      case '1bhk':
      case 'onebhk':
        return HomeLayoutTemplateType.oneBhk;
      case '2bhk':
      case 'twobhk':
        return HomeLayoutTemplateType.twoBhk;
      case '3bhk':
      case 'threebhk':
        return HomeLayoutTemplateType.threeBhk;
      case '4bhk':
      case 'fourbhk':
        return HomeLayoutTemplateType.fourBhk;
      case 'independenthouse':
      case 'house':
        return HomeLayoutTemplateType.independentHouse;
      case 'villa':
        return HomeLayoutTemplateType.villa;
      case 'pghostel':
      case 'hostel':
        return HomeLayoutTemplateType.pgHostel;
      case 'office':
        return HomeLayoutTemplateType.office;
      case 'retail':
      case 'retailstore':
        return HomeLayoutTemplateType.retailStore;
      case 'warehouse':
        return HomeLayoutTemplateType.warehouse;
      case 'coworking':
      case 'coworkingspace':
        return HomeLayoutTemplateType.coworkingSpace;
      case 'restaurant':
      case 'cafe':
        return HomeLayoutTemplateType.restaurant;
      case 'hotel':
      case 'guesthouse':
        return HomeLayoutTemplateType.hotel;
      case 'clinic':
      case 'hospital':
        return HomeLayoutTemplateType.clinic;
      case 'school':
      case 'institute':
        return HomeLayoutTemplateType.school;
      case 'factory':
      case 'industrial':
        return HomeLayoutTemplateType.factory;
      case 'customcommercial':
        return HomeLayoutTemplateType.customCommercial;
      case 'custom':
      default:
        return HomeLayoutTemplateType.twoBhk;
    }
  }
}

// Retain legacy CustomFloorDraft for backwards compatibility
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
