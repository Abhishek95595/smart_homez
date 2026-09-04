import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/device_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/property_provider.dart';
import '../profile_theme.dart';

/// Row of three compact stat cards displaying total devices, online devices, and homes count.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final propertyProvider = context.watch<PropertyProvider>();

    final int devices = deviceProvider.devices.isNotEmpty
        ? deviceProvider.devices.length
        : profileProvider.deviceCount;

    final int online = deviceProvider.devices.isNotEmpty
        ? deviceProvider.onlineCount
        : profileProvider.onlineDeviceCount;

    final int homes = profileProvider.homes.isNotEmpty
        ? profileProvider.homes.length
        : (propertyProvider.properties.isNotEmpty
              ? propertyProvider.properties.length
              : (profileProvider.profile?.homeCount ?? 0));

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.devices_other_rounded,
            label: 'DEVICES',
            value: '$devices',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.wifi_tethering_rounded,
            label: 'ONLINE',
            value: '$online',
            iconColorIsAccent: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.home_rounded,
            label: 'HOMES',
            value: '$homes',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool iconColorIsAccent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColorIsAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(ProfileTheme.mediumRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.secondarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: colors.accent),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
