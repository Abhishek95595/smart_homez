import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_layout_template.dart';
import '../providers/home_setup_provider.dart';

class CustomLayoutEditor extends StatelessWidget {
  final HomeSetupProvider provider;

  const CustomLayoutEditor({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isFlat = provider.hierarchyMode == HierarchyMode.flat;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Customize Structure',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hierarchy Mode Segmented Selector (Flat vs Floor-based)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeSegmentButton(
                    title: 'Flat (Home → Rooms)',
                    icon: Icons.meeting_room_outlined,
                    isSelected: isFlat,
                    onTap: () => provider.setHierarchyMode(HierarchyMode.flat),
                  ),
                ),
                Expanded(
                  child: _ModeSegmentButton(
                    title: 'Floors (Home → Floors → Rooms)',
                    icon: Icons.layers_outlined,
                    isSelected: !isFlat,
                    onTap: () =>
                        provider.setHierarchyMode(HierarchyMode.floorBased),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Dynamic editor content depending on hierarchy mode
          if (isFlat)
            _FlatRoomsEditor(provider: provider)
          else
            _FloorBasedEditor(provider: provider),
        ],
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegmentButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatRoomsEditor extends StatelessWidget {
  final HomeSetupProvider provider;

  const _FlatRoomsEditor({required this.provider});

  Future<void> _showAddRoomDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Room'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Study Room, Balcony',
              errorText: localError,
            ),
            onSubmitted: (value) {
              final err = provider.addCustomFlatRoom(value);
              if (err != null) {
                setDialogState(() => localError = err);
              } else {
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
                final err = provider.addCustomFlatRoom(controller.text);
                if (err != null) {
                  setDialogState(() => localError = err);
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    int index,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rename Room'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Room name',
              errorText: localError,
            ),
            onSubmitted: (value) {
              final err = provider.renameCustomFlatRoom(index, value);
              if (err != null) {
                setDialogState(() => localError = err);
              } else {
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
                final err = provider.renameCustomFlatRoom(
                  index,
                  controller.text,
                );
                if (err != null) {
                  setDialogState(() => localError = err);
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = provider.customFlatRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rooms (${rooms.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddRoomDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Room'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No rooms added. Tap "+ Add Room" to create one.',
                style: TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(rooms.length, (idx) {
              final name = rooms[idx];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showRenameDialog(context, idx, name),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showRenameDialog(context, idx, name),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => provider.removeCustomFlatRoom(idx),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _FloorBasedEditor extends StatelessWidget {
  final HomeSetupProvider provider;

  const _FloorBasedEditor({required this.provider});

  Future<void> _showAddFloorDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController(
      text: '${provider.customFloors.length}',
    );
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Floor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Floor Name',
                  hintText: 'e.g. Second Floor, Basement',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: levelCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Floor Level Number',
                  hintText: '0, 1, 2...',
                ),
              ),
              if (localError != null) ...[
                const SizedBox(height: 8),
                Text(
                  localError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final int level =
                    int.tryParse(levelCtrl.text) ??
                    provider.customFloors.length;
                final err = provider.addCustomFloor(nameCtrl.text, level);
                if (err != null) {
                  setDialogState(() => localError = err);
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Floor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRoomToFloorDialog(
    BuildContext context,
    int floorIndex,
  ) async {
    final controller = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Room to ${provider.customFloors[floorIndex].name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Room name',
              errorText: localError,
            ),
            onSubmitted: (value) {
              final err = provider.addRoomToFloor(floorIndex, value);
              if (err != null) {
                setDialogState(() => localError = err);
              } else {
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
                final err = provider.addRoomToFloor(
                  floorIndex,
                  controller.text,
                );
                if (err != null) {
                  setDialogState(() => localError = err);
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = provider.customFloors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Floors (${floors.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddFloorDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Floor'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (floors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No floors added. Tap "+ Add Floor" to create one.',
                style: TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: floors.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, floorIdx) {
              final floor = floors[floorIdx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${floor.name} (Level ${floor.level})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add room to floor',
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showAddRoomToFloorDialog(context, floorIdx),
                        ),
                        IconButton(
                          tooltip: 'Delete floor',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          onPressed: () => provider.removeCustomFloor(floorIdx),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (floor.rooms.isEmpty)
                      const Text(
                        'No rooms on this floor. Add at least one.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(floor.rooms.length, (roomIdx) {
                          final roomName = floor.rooms[roomIdx];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roomName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => provider.removeRoomFromFloor(
                                    floorIdx,
                                    roomIdx,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
