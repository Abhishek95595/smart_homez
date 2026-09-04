import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../profile_theme.dart';

/// Card showing account details like Full Name, Email, Mobile (if present), and Role.
/// Strictly excludes technical UUIDs, API credentials, and internal timestamps.
class ProfileDetailsCard extends StatelessWidget {
  const ProfileDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final profile = profileProvider.profile;

    final String name = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.name.isNotEmpty == true ? user!.name : 'Smart Home User');

    final String email = profile?.email?.isNotEmpty == true
        ? profile!.email!
        : (user?.email ?? '');

    final String phone = profile?.phone?.isNotEmpty == true
        ? profile!.phone!
        : (user?.phone ?? '');

    final String timezone = profile?.timezone?.isNotEmpty == true
        ? profile!.timezone!
        : '';

    final String role = auth.role.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ACCOUNT DETAILS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
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
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: name,
              ),
              _RowDivider(color: colors.divider),
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email.isNotEmpty ? email : 'Not provided',
                isPlaceholder: email.isEmpty,
              ),
              if (phone.isNotEmpty) ...[
                _RowDivider(color: colors.divider),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile Number',
                  value: phone,
                ),
              ],
              if (timezone.isNotEmpty) ...[
                _RowDivider(color: colors.divider),
                _DetailRow(
                  icon: Icons.public_rounded,
                  label: 'Time Zone',
                  value: timezone,
                ),
              ],
              _RowDivider(color: colors.divider),
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: role,
              ),
              _RowDivider(color: colors.divider),
              // Managed account indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Account details are managed by your administrator.',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.secondarySurface,
              borderRadius: BorderRadius.circular(ProfileTheme.smallRadius),
            ),
            child: Icon(icon, color: colors.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaceholder
                        ? colors.textSecondary
                        : colors.textPrimary,
                    fontSize: 14,
                    fontWeight: isPlaceholder
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final Color color;

  const _RowDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: color,
    );
  }
}
