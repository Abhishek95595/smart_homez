import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Home Location Card using Hasomi Light Theme design tokens.
/// Safely renders neutral Location Unavailable state when API data is missing.
class HomeLocationCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const HomeLocationCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    final bool isDataAvailable = data != null;
    final lat = data?['latitude']?.toString();
    final lng = data?['longitude']?.toString();
    final geofenceRadius = data?['geofenceRadius']?.toString();
    final ssid = data?['wifiSsid']?.toString() ?? data?['ssid']?.toString();
    final address = data?['address']?.toString();
    final hasCoords = lat != null && lng != null && lat != '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: colors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Home Location',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(EnvironmentTheme.largeRadius),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stylized Map-like Preview Header
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    EnvironmentTheme.mediumRadius,
                  ),
                  color: isDataAvailable
                      ? colors.accentSoft
                      : colors.secondarySurface,
                  border: Border.all(color: colors.border),
                ),
                child: Stack(
                  children: [
                    // Decorative Grid Lines
                    ...List.generate(
                      4,
                      (i) => Positioned(
                        left: 0,
                        right: 0,
                        top: (i + 1) * 16.0,
                        child: Container(
                          height: 0.5,
                          color: colors.textTertiary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    ...List.generate(
                      6,
                      (i) => Positioned(
                        top: 0,
                        bottom: 0,
                        left: (i + 1) * 50.0,
                        child: Container(
                          width: 0.5,
                          color: colors.textTertiary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Center Pin Icon
                    Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isDataAvailable
                            ? colors.accent
                            : colors.textTertiary,
                        size: 30,
                      ),
                    ),
                    // Geofence Ring
                    if (isDataAvailable)
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            color: colors.accent.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (address != null && address.isNotEmpty) ...[
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (!isDataAvailable) ...[
                Text(
                  'Location Unavailable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unable to retrieve home location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Location Detail Chips using Wrap to avoid narrow-width overflow
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LocationChip(
                    icon: Icons.my_location_rounded,
                    label: hasCoords ? '$lat, $lng' : 'Location unavailable',
                    colors: colors,
                  ),
                  if (geofenceRadius != null && geofenceRadius.isNotEmpty)
                    _LocationChip(
                      icon: Icons.radar_rounded,
                      label: '${geofenceRadius}m',
                      colors: colors,
                    ),
                  if (ssid != null && ssid.isNotEmpty)
                    _LocationChip(
                      icon: Icons.wifi_rounded,
                      label: ssid,
                      colors: colors,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final EnvironmentThemeData colors;

  const _LocationChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(EnvironmentTheme.smallRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
