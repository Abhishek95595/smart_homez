import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_setup_response.dart';

class SearchableRoomPickerModal extends StatefulWidget {
  final List<CreatedRoom> rooms;
  final List<CreatedFloor> floors;
  final String? selectedRoomId;
  final ValueChanged<String?> onRoomSelected;

  const SearchableRoomPickerModal({
    super.key,
    required this.rooms,
    this.floors = const [],
    required this.selectedRoomId,
    required this.onRoomSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<CreatedRoom> rooms,
    List<CreatedFloor> floors = const [],
    required String? selectedRoomId,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchableRoomPickerModal(
        rooms: rooms,
        floors: floors,
        selectedRoomId: selectedRoomId,
        onRoomSelected: (roomId) => Navigator.pop(ctx, roomId),
      ),
    );
  }

  @override
  State<SearchableRoomPickerModal> createState() =>
      _SearchableRoomPickerModalState();
}

class _SearchableRoomPickerModalState extends State<SearchableRoomPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredRooms = widget.rooms.where((room) {
      if (query.isEmpty) return true;
      return room.name.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Select Room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search rooms…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 12),

            // List of rooms
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Option: Leave Unassigned
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: widget.selectedRoomId == null
                        ? AppColors.primarySoft
                        : Colors.transparent,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Leave Unassigned',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: widget.selectedRoomId == null
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => widget.onRoomSelected(null),
                  ),
                  const Divider(height: 16),

                  if (filteredRooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No matching rooms found.',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredRooms.map((room) {
                      final isSelected = widget.selectedRoomId == room.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: isSelected
                              ? AppColors.primarySoft
                              : AppColors.surfaceElevated,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.meeting_room_outlined,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryDark,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            room.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => widget.onRoomSelected(room.id),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
