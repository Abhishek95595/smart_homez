import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/profile_provider.dart';
import '../../../models/robot_avatar.dart';
import '../../../widgets/robot_avatar.dart';
import '../profile_theme.dart';

/// Modal bottom sheet allowing the user to select from available Smart Homz companion avatars.
class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = ProfileTheme.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: colors.panel,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final selectedId = profileProvider.selectedAvatarId;
    final avatars = ProfileProvider.availableAvatars;

    final Color dragHandleColor = const Color(0xFFC7D1CF);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: dragHandleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Companion',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your Smart Homz companion avatar.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isSelected = avatar.id == selectedId;

                final Color cardBackground = isSelected
                    ? colors.accentSoft
                    : const Color(0xFFF7FAF9);

                final Color cardBorderColor = isSelected
                    ? colors.accent
                    : colors.border;

                return GestureDetector(
                  onTap: () {
                    context.read<ProfileProvider>().selectAvatar(avatar.id);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cardBorderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RobotAvatar(
                              type: RobotAvatarTypeX.fromStorageId(avatar.id),
                              size: 56,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              avatar.name,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.accent
                                    : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              avatar.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: colors.accent,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
