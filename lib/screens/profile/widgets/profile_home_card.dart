import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/device_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/property_provider.dart';
import '../../properties/homes_screen.dart';
import '../profile_theme.dart';

/// Card displaying the active home and its summary counts (floors, rooms, devices)
/// with proper singular/plural grammar and empty state handling.
class ProfileHomeCard extends StatelessWidget {
  const ProfileHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final propertyProvider = context.watch<PropertyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();

    final activeHome = profileProvider.activeHome;
    final primaryProperty = propertyProvider.properties.firstOrNull;

    final bool hasHomes =
        profileProvider.homes.isNotEmpty ||
        propertyProvider.properties.isNotEmpty ||
        (profileProvider.profile?.homeCount ?? 0) > 0;

    final String homeName = hasHomes
        ? (activeHome?.name.isNotEmpty == true
              ? activeHome!.name
              : (primaryProperty?.name.isNotEmpty == true
                    ? primaryProperty!.name
                    : 'Unnamed home'))
        : 'No homes configured yet';

    // Aggregate counts from actual provider models
    final int floorCount = propertyProvider.floors.isNotEmpty
        ? propertyProvider.floors.length
        : profileProvider.floorCount;

    final int roomCount = propertyProvider.rooms.isNotEmpty
        ? propertyProvider.rooms.length
        : profileProvider.roomCount;

    final int deviceCount = deviceProvider.devices.isNotEmpty
        ? deviceProvider.devices.length
        : profileProvider.deviceCount;

    final String floorLabel =
        '$floorCount ${floorCount == 1 ? 'floor' : 'floors'}';
    final String roomLabel = '$roomCount ${roomCount == 1 ? 'room' : 'rooms'}';
    final String deviceLabel =
        '$deviceCount ${deviceCount == 1 ? 'device' : 'devices'}';

    final String subtitle = hasHomes
        ? '$floorLabel · $roomLabel · $deviceLabel'
        : 'Tap to configure properties';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY HOME',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              if (hasHomes)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomesScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(ProfileTheme.largeRadius),
            splashColor: colors.accent.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.secondarySurface,
                      borderRadius: BorderRadius.circular(
                        ProfileTheme.smallRadius,
                      ),
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: colors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
