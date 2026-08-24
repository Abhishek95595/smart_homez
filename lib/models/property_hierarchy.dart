// Society/Facility hierarchy: Tenant -> Building -> Tower -> Floor -> Flat/Zone.

class Society {
  final String id;
  final String name;
  final String address;
  final List<Building> buildings;

  const Society({
    required this.id,
    required this.name,
    required this.address,
    required this.buildings,
  });
}

class Building {
  final String id;
  final String name;
  final List<Tower> towers;

  const Building({required this.id, required this.name, required this.towers});
}

class Tower {
  final String id;
  final String name;
  final List<Flat> flats;
  final List<String> commonAreas; // e.g. Lobby, Terrace, Basement

  const Tower({
    required this.id,
    required this.name,
    required this.flats,
    this.commonAreas = const [],
  });
}

class Flat {
  final String id;
  final String label; // e.g. "302"
  final int floor;
  final List<String> rooms; // Living Room, Kitchen, Bedroom...

  const Flat({
    required this.id,
    required this.label,
    required this.floor,
    this.rooms = const ['Living Room', 'Bedroom', 'Kitchen'],
  });
}

/// Locally managed hierarchy used by the property-management screens.
///
/// These flat records intentionally use parent IDs instead of nested objects.
/// That keeps CRUD operations simple now and maps cleanly to separate Firebase
/// collections later.
class ManagedProperty {
  final String id;
  final String name;
  final String address;
  final String category;
  final String propertyType;
  final String timezone;
  final String currency;
  final String? businessStart;
  final String? businessEnd;
  final String? latitude;
  final String? longitude;

  const ManagedProperty({
    required this.id,
    required this.name,
    required this.address,
    this.category = 'Residential',
    this.propertyType = 'House',
    this.timezone = 'Asia/Kolkata',
    this.currency = 'INR',
    this.businessStart,
    this.businessEnd,
    this.latitude,
    this.longitude,
  });

  bool get isCommercial => category.toLowerCase() == 'commercial';

  ManagedProperty copyWith({
    String? name,
    String? address,
    String? category,
    String? propertyType,
    String? timezone,
    String? currency,
    String? businessStart,
    String? businessEnd,
    String? latitude,
    String? longitude,
    bool clearBusinessHours = false,
  }) {
    return ManagedProperty(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      propertyType: propertyType ?? this.propertyType,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      businessStart: clearBusinessHours
          ? null
          : businessStart ?? this.businessStart,
      businessEnd: clearBusinessHours ? null : businessEnd ?? this.businessEnd,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'category': category,
    'propertyType': propertyType,
    'timezone': timezone,
    'currency': currency,
    'businessStart': businessStart,
    'businessEnd': businessEnd,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory ManagedProperty.fromJson(Map<String, dynamic> json) {
    return ManagedProperty(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      category: json['category'] as String? ?? 'Residential',
      propertyType: json['propertyType'] as String? ?? 'House',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      currency: json['currency'] as String? ?? 'INR',
      businessStart: json['businessStart'] as String?,
      businessEnd: json['businessEnd'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
    );
  }
}

class ManagedFloor {
  final String id;
  final String propertyId;
  final String name;
  final int level;

  const ManagedFloor({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.level,
  });

  ManagedFloor copyWith({String? name, int? level}) {
    return ManagedFloor(
      id: id,
      propertyId: propertyId,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'propertyId': propertyId,
    'name': name,
    'level': level,
  };

  factory ManagedFloor.fromJson(Map<String, dynamic> json) {
    return ManagedFloor(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
    );
  }
}

class ManagedRoom {
  final String id;
  final String? floorId;
  final String? propertyId;
  final String name;
  final String type;

  const ManagedRoom({
    required this.id,
    this.floorId,
    this.propertyId,
    required this.name,
    required this.type,
  });

  ManagedRoom copyWith({
    String? name,
    String? type,
    String? floorId,
    String? propertyId,
  }) {
    return ManagedRoom(
      id: id,
      floorId: floorId ?? this.floorId,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'floorId': floorId,
    if (propertyId != null) 'propertyId': propertyId,
    'name': name,
    'type': type,
  };

  factory ManagedRoom.fromJson(Map<String, dynamic> json) {
    return ManagedRoom(
      id: json['id'] as String,
      floorId: json['floorId'] as String?,
      propertyId: json['propertyId'] as String?,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'Other',
    );
  }
}
