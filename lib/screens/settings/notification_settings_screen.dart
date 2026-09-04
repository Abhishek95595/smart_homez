import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_settings_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationSettingsProvider>();

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left Menu Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (ctx) => AppNavigationLeading.drawer(
                            color: const Color(0xFF0F172A),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                ),

                // Center Title & Subtitle
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage how you stay informed and safe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            // Top Hero Overview Card
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF021E1D),
                      Color(0xFF053835),
                      Color(0xFF022725),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004D40).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _HeroPatternPainter(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Row(
                      children: [
                        // Glowing 3D-styled Bell Avatar
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                const Color(0xFF00A38E).withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                              stops: const [0.35, 0.7, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF074E49),
                                    Color(0xFF022C2A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00E5FF,
                                  ).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: Color(0xFF5EEAD4),
                                  size: 27,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Hero Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Push & Safety Alerts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Customize real-time push, critical hazard, and plan notifications.',
                                style: TextStyle(
                                  color: Color(0xFFCCFBF1),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Section Header
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'NOTIFICATION CHANNELS',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            // 1. General Notifications Card
            _ChannelCard(
              icon: Icons.devices_other_rounded,
              iconColor: const Color(0xFF00A38E),
              iconBgColor: const Color(0xFFE6F7F5),
              title: 'General Notifications',
              subtitle: 'Devices & status alerts',
              subtitleColor: const Color(0xFF0D9488),
              description:
                  'Sends push notifications when appliances turn on/off, automations trigger, or routine status changes occur.',
              value: notifProvider.generalNotifications,
              activeSwitchColor: const Color(0xFF0D9488),
              onChanged: (val) => notifProvider.setGeneralNotifications(val),
            ),
            const SizedBox(height: 16),

            // 2. Critical Notifications Card
            _ChannelCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFFF1F2),
              title: 'Critical Notifications',
              subtitle: 'Life-safety alerts',
              subtitleColor: const Color(0xFFE11D48),
              badgeText: 'CRITICAL',
              badgeColor: const Color(0xFFE11D48),
              badgeBgColor: const Color(0xFFFFE4E6),
              description:
                  'Immediate high-priority push notifications for hazardous life-safety alerts such as fire alarm, gas leak & water overflow.',
              value: notifProvider.criticalNotifications,
              activeSwitchColor: const Color(0xFFE11D48),
              onChanged: (val) {
                notifProvider.toggleCriticalWithConfirmation(context, val);
              },
            ),
            const SizedBox(height: 16),

            // 3. Plan Notifications Card
            _ChannelCard(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF3E8FF),
              title: 'Plan Notifications',
              subtitle: 'Subscription & offers',
              subtitleColor: const Color(0xFF7C3AED),
              description:
                  'Notifies you of upcoming subscription expirations, renewal reminders, discounts, and custom upgrade deals.',
              value: notifProvider.planNotifications,
              activeSwitchColor: const Color(0xFF7C3AED),
              onChanged: (val) => notifProvider.setPlanNotifications(val),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pattern painter drawing the subtle matrix dots on the hero card
class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const spacing = 11.0;
    const radius = 1.2;

    for (double x = size.width - 100; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pixel-matched Notification Channel card with squircle icon, colored subtitle,
/// description body, custom colored switch, and subtle chevron arrow.
class _ChannelCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final String description;
  final bool value;
  final Color activeSwitchColor;
  final ValueChanged<bool> onChanged;

  const _ChannelCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
    required this.description,
    required this.value,
    required this.activeSwitchColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Squircle Icon Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 26)),
            ),
            const SizedBox(width: 14),

            // Middle Column (Title, Tag, Description)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Badge Row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor ?? const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor ?? const Color(0xFFE11D48),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Colored Subtitle Tag
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Multi-line Detailed Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Action Column (Switch & Chevron)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Switch.adaptive(
                  value: value,
                  activeColor: Colors.white,
                  activeTrackColor: activeSwitchColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  trackOutlineColor: const WidgetStatePropertyAll<Color>(
                    Colors.transparent,
                  ),
                  thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
                  trackColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => states.contains(WidgetState.selected)
                        ? activeSwitchColor
                        : const Color(0xFFE2E8F0),
                  ),
                  onChanged: onChanged,
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
