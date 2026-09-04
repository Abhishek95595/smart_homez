import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/profile_provider.dart';
import '../profile_theme.dart';
import 'avatar_picker_sheet.dart';
import 'avatar_progress_ring.dart';

/// Compact profile hero section displaying user avatar, online status pill, name, role badge, and customize button.
class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key});

  void _showCustomizeDialog(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final Color buttonTextColor = Colors.white;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(
                Icons.manage_accounts_rounded,
                color: colors.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Customize Profile',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.raised,
                  borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: colors.warmAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account identity details (Name, Email, Phone) are managed by your administrator.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'You can customize your active companion avatar icon below:',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                AvatarPickerSheet.show(context);
              },
              icon: const Icon(Icons.smart_toy_rounded, size: 16),
              label: const Text(
                'Change Avatar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final profile = profileProvider.profile;

    final String displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.name.isNotEmpty == true ? user!.name : 'Smart Home User');

    final String displayEmail = profile?.email?.isNotEmpty == true
        ? profile!.email!
        : (user?.email ?? '');

    final String initials = user?.avatarInitials.isNotEmpty == true
        ? user!.avatarInitials
        : (displayName.length >= 2
              ? displayName.substring(0, 2).toUpperCase()
              : 'SH');

    final int deviceCount = deviceProvider.devices.isNotEmpty
        ? deviceProvider.devices.length
        : profileProvider.deviceCount;

    final int onlineCount = deviceProvider.devices.isNotEmpty
        ? deviceProvider.onlineCount
        : profileProvider.onlineDeviceCount;

    final double onlineRatio = deviceCount > 0
        ? (onlineCount / deviceCount).clamp(0.0, 1.0)
        : 0.0;

    final avatar = profileProvider.currentAvatar;
    final role = auth.role;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with progress ring
          AvatarProgressRing(
            progress: onlineRatio,
            avatar: avatar,
            fallbackInitials: initials,
            onEdit: () => AvatarPickerSheet.show(context),
          ),
          const SizedBox(height: 14),

          // Device status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$onlineCount / $deviceCount DEVICES ONLINE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // User Full Name
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (displayEmail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              displayEmail,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Badges Row (Role + Permission)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _HeroBadge(
                icon: Icons.shield_outlined,
                label: role.label,
                backgroundColor: colors.accentSoft,
                textColor: colors.accent,
              ),
              if (profile?.permissionLevel != null &&
                  profile!.permissionLevel!.isNotEmpty)
                _HeroBadge(
                  icon: Icons.verified_user_outlined,
                  label: profile.permissionLevel!.toUpperCase(),
                  backgroundColor: colors.warmAccentSoft,
                  textColor: colors.warmAccent,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Customize Profile Button
          OutlinedButton.icon(
            onPressed: () => _showCustomizeDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              side: BorderSide(
                color: colors.accent.withValues(alpha: 0.4),
                width: 1.2,
              ),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            ),
            icon: Icon(Icons.edit_outlined, size: 15, color: colors.accent),
            label: const Text('Customize Profile'),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
