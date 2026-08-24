import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/models/home_layout_template.dart';
import '../providers/home_setup_provider.dart';
import 'device_room_assignment_tile.dart';

class DeviceAssignmentStep extends StatelessWidget {
  final HomeSetupProvider provider;
  final bool canManage;
  final VoidCallback onComplete;

  const DeviceAssignmentStep({
    super.key,
    required this.provider,
    required this.canManage,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final home = provider.createdHome;
    final devices = provider.unassignedDevices;
    final totalCount = provider.totalDevicesCount;
    final assignedCount = provider.assignedCount;
    final partialFailures = provider.partialFailures;

    final failureMap = {for (final f in partialFailures) f.deviceId: f.error};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Home Created Success Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${home?.home.name ?? "Home"} Created!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.availableRooms.length} rooms generated from ${provider.selectedTemplate.title}.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header & Batch Action Controls
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Devices to Rooms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalCount > 0
                          ? '$assignedCount of $totalCount devices assigned'
                          : 'Discovering unassigned devices…',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (devices.isNotEmpty && canManage) ...[
                TextButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => provider.assignAllSuggested(),
                  child: const Text('Auto-Assign'),
                ),
                TextButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => provider.clearAllAssignments(),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Loading Devices State
          if (provider.isFetchingDevices) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Scanning for unassigned devices…',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (provider.deviceFetchError != null) ...[
            // Device Fetch Error with Retry
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.deviceFetchError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => provider.fetchUnassignedDevices(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry Fetching Devices'),
                  ),
                ],
              ),
            ),
          ] else if (devices.isEmpty) ...[
            // Zero Unassigned Devices Found
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.devices_other_rounded,
                      color: AppColors.textFaint,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No Unassigned Devices Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your home structure is ready. You can pair and assign devices later anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // List of Device Assignment Tiles
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceRoomAssignmentTile(
                  device: device,
                  availableRooms: provider.availableRooms,
                  availableFloors: home?.floors ?? const [],
                  selectedRoomId: provider.deviceAssignments[device.id],
                  failureMessage: failureMap[device.id],
                  enabled: canManage && !provider.isSubmitting,
                  onRoomChanged: (roomId) =>
                      provider.assignDevice(device.id, roomId),
                );
              },
            ),
          ],
          const SizedBox(height: 20),

          // Partial Failures Alert & Retry Only Failed
          if (partialFailures.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${partialFailures.length} assignments failed to save.',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: provider.isSubmitting
                        ? null
                        : () async {
                            final ok = await provider.retryFailedAssignments(
                              canManage: canManage,
                            );
                            if (ok) onComplete();
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry Failed Assignments'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Error Message Banner
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Finish / Complete Setup Button
          FilledButton.icon(
            onPressed:
                (!canManage ||
                    provider.isSubmitting ||
                    provider.isFetchingDevices)
                ? null
                : () async {
                    final ok = await provider.submitAssignments(
                      canManage: canManage,
                    );
                    if (ok) {
                      onComplete();
                    }
                  },
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              provider.isSubmitting
                  ? 'Saving Assignments…'
                  : (devices.isEmpty ? 'Finish Setup' : 'Complete Onboarding'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
