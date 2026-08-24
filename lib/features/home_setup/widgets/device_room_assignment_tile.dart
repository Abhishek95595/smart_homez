import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_setup_response.dart';
import '../data/models/unassigned_device_model.dart';
import 'searchable_room_picker.dart';

class DeviceRoomAssignmentTile extends StatelessWidget {
  final UnassignedDevice device;
  final List<CreatedRoom> availableRooms;
  final List<CreatedFloor> availableFloors;
  final String? selectedRoomId;
  final String? failureMessage;
  final ValueChanged<String?> onRoomChanged;
  final bool enabled;

  const DeviceRoomAssignmentTile({
    super.key,
    required this.device,
    required this.availableRooms,
    this.availableFloors = const [],
    required this.selectedRoomId,
    this.failureMessage,
    required this.onRoomChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoom = availableRooms
        .where((r) => r.id == selectedRoomId)
        .firstOrNull;
    final bool hasAssignment = selectedRoom != null;
    final bool hasFailure = failureMessage != null;

    // Format confidence percentage if provided by backend
    final String? confidenceText =
        (device.confidence != null && device.confidence! > 0)
        ? '${(device.confidence! * 100).toInt()}% match'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasFailure
            ? AppColors.danger.withValues(alpha: 0.04)
            : (hasAssignment ? AppColors.surface : AppColors.surfaceElevated),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFailure
              ? AppColors.danger.withValues(alpha: 0.4)
              : (hasAssignment
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.divider),
          width: hasAssignment || hasFailure ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header Row (Icon + Name + Type + Confidence Badge)
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasAssignment
                      ? AppColors.primarySoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasAssignment
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.divider,
                  ),
                ),
                child: Icon(
                  device.iconData,
                  color: hasAssignment
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textFaint,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (confidenceText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        confidenceText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Room Assignment Selector Button & Clear Action
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: enabled
                      ? () async {
                          final result = await SearchableRoomPickerModal.show(
                            context,
                            rooms: availableRooms,
                            floors: availableFloors,
                            selectedRoomId: selectedRoomId,
                          );
                          // User can select a room ID or null (unassigned)
                          if (result != selectedRoomId) {
                            onRoomChanged(result);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: hasAssignment
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasAssignment
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 16,
                          color: hasAssignment
                              ? AppColors.primaryDark
                              : AppColors.textFaint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedRoom?.name ?? 'Assign to Room…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasAssignment
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: hasAssignment
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasAssignment && enabled) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Unassign device',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => onRoomChanged(null),
                ),
              ],
            ],
          ),

          // Partial failure notice (if this device failed assignment)
          if (hasFailure) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    failureMessage!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
