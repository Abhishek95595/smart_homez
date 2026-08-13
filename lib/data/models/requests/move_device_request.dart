/// Request model for moving a device based on Swagger schema (MoveDeviceRequest).
class MoveDeviceRequest {
  const MoveDeviceRequest._({this.roomId, this.floorId});

  factory MoveDeviceRequest.toRoom(String roomId) {
    return MoveDeviceRequest._(roomId: roomId);
  }

  factory MoveDeviceRequest.toFloor(String floorId) {
    return MoveDeviceRequest._(floorId: floorId);
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
