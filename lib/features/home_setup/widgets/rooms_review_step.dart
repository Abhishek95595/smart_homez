import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/property_setup_draft.dart';
import '../providers/home_setup_provider.dart';

class RoomsReviewStep extends StatelessWidget {
  final HomeSetupProvider provider;

  const RoomsReviewStep({super.key, required this.provider});

  Future<void> _showAddRoomDialog(
    BuildContext context, {
    String? floorLocalId,
    String? floorName,
  }) async {
    final controller = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            floorName != null ? 'Add room to $floorName' : 'Add Room or Space',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Study Room, Balcony, Guest Suite',
              errorText: localError,
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) {
                setDialogState(() => localError = 'Room name cannot be empty.');
              } else {
                provider.addRoom(trimmed, floorLocalId: floorLocalId);
                Navigator.pop(ctx);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setDialogState(
                    () => localError = 'Room name cannot be empty.',
                  );
                } else {
                  provider.addRoom(trimmed, floorLocalId: floorLocalId);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Room'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMultiFloor = provider.isMultiFloor;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your rooms',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rooms can be added or deleted now. You can manage room settings anytime after property setup.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          if (isMultiFloor) ...[
            // Multi-Floor View (Grouped by Floor)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.draftFloors.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, floorIndex) {
                final floor = provider.draftFloors[floorIndex];
                return _FloorSectionCard(
                  floor: floor,
                  onAddRoom: () => _showAddRoomDialog(
                    context,
                    floorLocalId: floor.localId,
                    floorName: floor.name,
                  ),
                  onDeleteRoom: (roomLocalId) => provider.deleteRoom(
                    roomLocalId,
                    floorLocalId: floor.localId,
                  ),
                );
              },
            ),
          ] else ...[
            // Single-Level Flat Rooms View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rooms (${provider.draftRooms.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddRoomDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('+ Add room or space'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (provider.draftRooms.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 32,
                        color: AppColors.textFaint,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No rooms in this space.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showAddRoomDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add room or space'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.draftRooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final room = provider.draftRooms[index];
                  return _ReadOnlyRoomCardTile(
                    roomName: room.name,
                    onDelete: () => provider.deleteRoom(room.localId),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _FloorSectionCard extends StatelessWidget {
  final DraftFloor floor;
  final VoidCallback onAddRoom;
  final ValueChanged<String> onDeleteRoom;

  const _FloorSectionCard({
    required this.floor,
    required this.onAddRoom,
    required this.onDeleteRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    floor.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddRoom,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    '+ Add room to ${floor.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Floor Rooms List
          if (floor.rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No rooms on this floor. Tap "+ Add room" above.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textFaint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: floor.rooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final room = floor.rooms[idx];
                return _ReadOnlyRoomCardTile(
                  roomName: room.name,
                  onDelete: () => onDeleteRoom(room.localId),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyRoomCardTile extends StatelessWidget {
  final String roomName;
  final VoidCallback onDelete;

  const _ReadOnlyRoomCardTile({required this.roomName, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Room Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Room Name (Read-Only)
          Expanded(
            child: Text(
              roomName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Red Trash Bin Delete Icon (Min 44x44 Touch Target)
          IconButton(
            tooltip: 'Delete room',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
