import 'package:flutter/material.dart';

import '../../family/family_invite_screen.dart';
import '../environment_theme.dart';

/// Family Presence Card rendering active presence state from API data.
/// Distinguishes between explicit Home Empty state vs API null/failure Presence Unavailable state.
class FamilyPresenceCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const FamilyPresenceCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    final bool isDataAvailable = data != null;

    final homeState = data?['homeState']?.toString() ?? 'unknown';
    final rawMembers = data?['members'];
    final List<Map<String, dynamic>> members = (rawMembers is List)
        ? rawMembers
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
        : const [];

    final int homeCount = members.where((m) {
      final s = m['status']?.toString().toLowerCase();
      return s == 'home' || s == 'present';
    }).length;

    final bool isOccupied =
        isDataAvailable &&
        (homeState == 'occupied' || homeState == 'home' || homeCount > 0);

    final String titleText = isDataAvailable
        ? (isOccupied ? 'Home Occupied' : 'Home Empty')
        : 'Presence Unavailable';

    final String subtitleText = isDataAvailable
        ? (members.isNotEmpty
              ? (homeCount == members.length
                    ? 'All family members are home'
                    : '$homeCount member${homeCount == 1 ? '' : 's'} at home')
              : (isOccupied
                    ? 'Home presence active'
                    : 'No family members currently home'))
        : 'Unable to retrieve family presence';

    final String badgeText = isDataAvailable
        ? (isOccupied ? 'ACTIVE' : 'AWAY')
        : 'UNAVAILABLE';

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
                Icons.people_alt_rounded,
                color: colors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Family Presence',
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyInviteScreen()),
              );
            },
            borderRadius: BorderRadius.circular(EnvironmentTheme.largeRadius),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.panel,
                borderRadius: BorderRadius.circular(
                  EnvironmentTheme.largeRadius,
                ),
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
                  // Status Header Row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDataAvailable
                              ? colors.accentSoft
                              : colors.secondarySurface,
                          borderRadius: BorderRadius.circular(
                            EnvironmentTheme.smallRadius,
                          ),
                        ),
                        child: Icon(
                          isOccupied ? Icons.home_rounded : Icons.home_outlined,
                          color: isDataAvailable
                              ? colors.accent
                              : colors.textTertiary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDataAvailable
                              ? colors.accentSoft
                              : colors.secondarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDataAvailable
                                ? colors.accent
                                : colors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),

                  // Real member list if provided by API
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(color: colors.divider, height: 1),
                    const SizedBox(height: 14),
                    ...members.map((m) {
                      final name = m['name']?.toString() ?? 'Member';
                      final status =
                          m['status']?.toString().toLowerCase() ?? 'unknown';
                      final isHome = status == 'home' || status == 'present';
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isHome
                                    ? colors.accent
                                    : colors.textTertiary,
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isHome
                                    ? colors.accentSoft
                                    : colors.secondarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHome ? 'Home' : 'Away',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isHome
                                      ? colors.accent
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
