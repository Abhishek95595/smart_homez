import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class DraftRoom {
  final String localId;
  final String name;
  final bool userAdded;

  DraftRoom({String? localId, required this.name, this.userAdded = false})
    : localId = localId ?? _uuid.v4();

  DraftRoom copyWith({String? name, bool? userAdded}) {
    return DraftRoom(
      localId: localId,
      name: name ?? this.name,
      userAdded: userAdded ?? this.userAdded,
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'name': name,
    'userAdded': userAdded,
  };
}

class DraftFloor {
  final String localId;
  final String name;
  final int level;
  final List<DraftRoom> rooms;

  DraftFloor({
    String? localId,
    required this.name,
    required this.level,
    List<DraftRoom>? rooms,
  }) : localId = localId ?? _uuid.v4(),
       rooms = rooms != null ? List.unmodifiable(rooms) : const [];

  DraftFloor copyWith({String? name, int? level, List<DraftRoom>? rooms}) {
    return DraftFloor(
      localId: localId,
      name: name ?? this.name,
      level: level ?? this.level,
      rooms: rooms != null ? List.unmodifiable(rooms) : this.rooms,
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'name': name,
    'level': level,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };
}
