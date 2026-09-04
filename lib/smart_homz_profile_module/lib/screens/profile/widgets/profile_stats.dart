import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/profile_provider.dart';
import '../profile_theme.dart';

/// Row of three compact stat cards displaying total devices, online devices, and homes count.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final int devices = profileProvider.deviceCount;
    final int online = profileProvider.onlineDeviceCount;
    final int homes = profileProvider.homes.isNotEmpty
        ? profileProvider.homes.length
        : (profileProvider.profile?.homeCount ?? 1);

    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'DEVICES', value: '$devices'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'ONLINE', value: '$online'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'HOMES', value: '$homes'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(ProfileTheme.mediumRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
