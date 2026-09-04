import 'models/home_setup_response.dart';
import 'models/unassigned_device_model.dart';

class RoomSuggestionService {
  const RoomSuggestionService();

  /// Resolves the optimal room assignment for a device given the list of created rooms.
  ///
  /// Priority:
  /// 1. Direct Backend Suggested Room ID (verified against [availableRooms])
  /// 2. Direct Backend Suggested Room Name (matched case-insensitively with [availableRooms])
  /// 3. Fallback Isolated Keyword Matching (isolated to this service only if backend provides no suggestion)
  /// 4. Returns null (remain unassigned) if no valid match exists.
  String? resolveSuggestedRoomId({
    required UnassignedDevice device,
    required List<CreatedRoom> availableRooms,
  }) {
    if (availableRooms.isEmpty) return null;

    final Map<String, CreatedRoom> idMap = {
      for (final room in availableRooms) room.id: room,
    };

    // 1. Verify backend suggested room ID
    if (device.suggestedRoomId != null &&
        device.suggestedRoomId!.trim().isNotEmpty) {
      final String trimmedId = device.suggestedRoomId!.trim();
      if (idMap.containsKey(trimmedId)) {
        return trimmedId;
      }
    }

    // 2. Check backend suggested room name match
    if (device.suggestedRoomName != null &&
        device.suggestedRoomName!.trim().isNotEmpty) {
      final String targetName = device.suggestedRoomName!.trim().toLowerCase();
      final matched = availableRooms.where(
        (r) => r.name.trim().toLowerCase() == targetName,
      );
      if (matched.isNotEmpty) {
        return matched.first.id;
      }
    }

    // 3. Fallback keyword matching (isolated here if backend didn't provide suggestion)
    return _fallbackKeywordMatch(device.name, availableRooms);
  }

  /// Isolated fallback helper matching keywords in device name to room names
  String? _fallbackKeywordMatch(
    String deviceName,
    List<CreatedRoom> availableRooms,
  ) {
    final String normDeviceName = deviceName.trim().toLowerCase();

    // Map common room keywords
    final Map<String, List<String>> keywordGroups = {
      'living': ['living', 'hall', 'drawing', 'parlor', 'lounge'],
      'master': ['master bedroom', 'master bed', 'mbd', 'master'],
      'bed': ['bedroom', 'bed room', 'guest bed', 'kids bed'],
      'kitchen': ['kitchen', 'kitchenette', 'pantry', 'cook'],
      'dining': ['dining', 'dinning'],
      'bath': [
        'bath',
        'bathroom',
        'washroom',
        'toilet',
        'powder room',
        'restroom',
      ],
      'balcony': ['balcony', 'terrace', 'patio', 'deck', 'veranda'],
      'foyer': ['foyer', 'entry', 'entrance', 'lobby', 'porch'],
      'office': ['office', 'study', 'work'],
    };

    for (final group in keywordGroups.entries) {
      final List<String> triggers = group.value;
      final bool deviceMatchesTrigger = triggers.any(
        (t) => normDeviceName.contains(t),
      );

      if (deviceMatchesTrigger) {
        // Find room that best matches these triggers
        for (final trigger in triggers) {
          final matchedRoom = availableRooms.where(
            (r) => r.name.toLowerCase().contains(trigger),
          );
          if (matchedRoom.isNotEmpty) {
            return matchedRoom.first.id;
          }
        }
      }
    }

    return null;
  }
}
