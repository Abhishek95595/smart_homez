class HomeSetupResult {
  final CreatedHome home;
  final String structureType;
  final List<CreatedFloor> floors;
  final List<CreatedRoom> rooms;

  const HomeSetupResult({
    required this.home,
    this.structureType = 'flat',
    this.floors = const [],
    this.rooms = const [],
  });

  bool get isFlat => structureType.toLowerCase() == 'flat' || floors.isEmpty;

  /// Returns all rooms whether directly at root or under floors.
  List<CreatedRoom> get allRooms {
    if (rooms.isNotEmpty) return rooms;
    final List<CreatedRoom> combined = [];
    for (final floor in floors) {
      combined.addAll(floor.rooms);
    }
    return combined;
  }

  factory HomeSetupResult.fromJson(Map<String, dynamic> json) {
    // Handle either nested home object or flat home fields in root map
    final dynamic homeRaw = json['home'] ?? json['data']?['home'] ?? json;
    final Map<String, dynamic> homeMap = homeRaw is Map
        ? Map<String, dynamic>.from(homeRaw)
        : <String, dynamic>{};

    final createdHome = CreatedHome.fromJson(homeMap);

    final String structure =
        (json['structure_type'] ??
                json['structureType'] ??
                (json['floors'] is List &&
                        (json['floors'] as List).isNotEmpty &&
                        !(json['rooms'] is List &&
                            (json['rooms'] as List).isNotEmpty)
                    ? 'floor_based'
                    : 'flat'))
            .toString();

    // Parse floors
    final List<CreatedFloor> parsedFloors = [];
    final dynamic floorsRaw = json['floors'] ?? json['data']?['floors'];
    if (floorsRaw is List) {
      for (final f in floorsRaw) {
        if (f is Map) {
          parsedFloors.add(
            CreatedFloor.fromJson(
              Map<String, dynamic>.from(f),
              homeId: createdHome.id,
            ),
          );
        }
      }
    }

    // Parse flat rooms
    final List<CreatedRoom> parsedRooms = [];
    final dynamic roomsRaw = json['rooms'] ?? json['data']?['rooms'];
    if (roomsRaw is List) {
      for (final r in roomsRaw) {
        if (r is Map) {
          parsedRooms.add(
            CreatedRoom.fromJson(
              Map<String, dynamic>.from(r),
              homeId: createdHome.id,
            ),
          );
        }
      }
    }

    // If root rooms are empty but floors have rooms, also collect them
    if (parsedRooms.isEmpty && parsedFloors.isNotEmpty) {
      for (final f in parsedFloors) {
        parsedRooms.addAll(f.rooms);
      }
    }

    return HomeSetupResult(
      home: createdHome,
      structureType: structure,
      floors: parsedFloors,
      rooms: parsedRooms,
    );
  }

  Map<String, dynamic> toJson() => {
    'home': home.toJson(),
    'structure_type': structureType,
    'floors': floors.map((f) => f.toJson()).toList(),
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };
}

class CreatedHome {
  final String id;
  final String name;
  final String? address;

  const CreatedHome({required this.id, required this.name, this.address});

  factory CreatedHome.fromJson(Map<String, dynamic> json) {
    return CreatedHome(
      id: (json['id'] ?? json['home_id'] ?? json['homeId'] ?? '').toString(),
      name: (json['name'] ?? json['home_name'] ?? json['homeName'] ?? 'My Home')
          .toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (address != null) 'address': address,
  };
}

class CreatedFloor {
  final String id;
  final String homeId;
  final String name;
  final int floorNumber;
  final List<CreatedRoom> rooms;

  const CreatedFloor({
    required this.id,
    required this.homeId,
    required this.name,
    required this.floorNumber,
    this.rooms = const [],
  });

  factory CreatedFloor.fromJson(
    Map<String, dynamic> json, {
    String homeId = '',
  }) {
    final String floorId =
        (json['id'] ?? json['floor_id'] ?? json['floorId'] ?? '').toString();
    final String resolvedHomeId = (json['home_id'] ?? json['homeId'] ?? homeId)
        .toString();

    final List<CreatedRoom> floorRooms = [];
    final dynamic roomsRaw = json['rooms'];
    if (roomsRaw is List) {
      for (final r in roomsRaw) {
        if (r is Map) {
          floorRooms.add(
            CreatedRoom.fromJson(
              Map<String, dynamic>.from(r),
              homeId: resolvedHomeId,
              floorId: floorId,
            ),
          );
        }
      }
    }

    return CreatedFloor(
      id: floorId,
      homeId: resolvedHomeId,
      name: (json['name'] ?? json['floor_name'] ?? json['floorName'] ?? 'Floor')
          .toString(),
      floorNumber:
          (json['floor_number'] ?? json['floorNumber'] ?? json['level'] as num?)
              ?.toInt() ??
          0,
      rooms: floorRooms,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'home_id': homeId,
    'name': name,
    'floor_number': floorNumber,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };
}

class CreatedRoom {
  final String id;
  final String homeId;
  final String? floorId;
  final String name;
  final String type;

  const CreatedRoom({
    required this.id,
    this.homeId = '',
    this.floorId,
    required this.name,
    this.type = 'Room',
  });

  factory CreatedRoom.fromJson(
    Map<String, dynamic> json, {
    String homeId = '',
    String? floorId,
  }) {
    return CreatedRoom(
      id: (json['id'] ?? json['room_id'] ?? json['roomId'] ?? '').toString(),
      homeId: (json['home_id'] ?? json['homeId'] ?? homeId).toString(),
      floorId: (json['floor_id'] ?? json['floorId'] ?? floorId)?.toString(),
      name: (json['name'] ?? json['room_name'] ?? json['roomName'] ?? 'Room')
          .toString(),
      type: (json['type'] ?? json['room_type'] ?? json['roomType'] ?? 'Room')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'home_id': homeId,
    if (floorId != null) 'floor_id': floorId,
    'name': name,
    'type': type,
  };
}
