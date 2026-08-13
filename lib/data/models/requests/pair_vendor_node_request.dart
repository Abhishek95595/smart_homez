/// Request model for pairing a node based on Swagger schema (PairNodeRequest).
class PairVendorNodeRequest {
  const PairVendorNodeRequest._({this.roomId, this.floorId});

  factory PairVendorNodeRequest.toRoom(String roomId) {
    return PairVendorNodeRequest._(roomId: roomId);
  }

  factory PairVendorNodeRequest.toFloor(String floorId) {
    return PairVendorNodeRequest._(floorId: floorId);
  }

  final String? roomId;
  final String? floorId;

  Map<String, dynamic> toJson() {
    if ((roomId == null) == (floorId == null)) {
      throw StateError('Exactly one of room_id or floor_id must be provided.');
    }

    return {
      if (roomId != null) 'room_id': roomId,
      if (floorId != null) 'floor_id': floorId,
    };
  }
}
