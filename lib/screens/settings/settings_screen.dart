import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';
import '../auth/login_screen.dart';
import '../integrations/integrations_screen.dart';
import '../privacy/privacy_policy_screen.dart';
import '../services_module/services_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final bool _pushEnabled = true;
  final bool _criticalOnly = false;
  final bool _emailAlerts = true;
  bool _soundEffects = true;

  String _language = 'English';
  String _temperatureUnit = '°C';
  String _timeFormat = '12-Hour';

  @override
  Widget build(BuildContext context) {
    final activeAlerts = context.watch<AlertProvider>().activeAlerts.length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(
              alertCount: activeAlerts,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onAlerts: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
              },
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  const _SettingsHeroCard(),
                  const SizedBox(height: 18),
                  _SettingsSection(
                    icon: Icons.settings_suggest_outlined,
                    title: 'App Preferences',
                    children: [
                      _SettingRow(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: _language,
                        trailing: _ChevronValue(value: _language),
                        onTap: _chooseLanguage,
                      ),
                      _SettingRow(
                        icon: Icons.device_thermostat_rounded,
                        title: 'Temperature Unit',
                        subtitle: _temperatureUnit == '°C'
                            ? 'Celsius (°C)'
                            : 'Fahrenheit (°F)',
                        trailing: _SegmentedChoice(
                          values: const ['°C', '°F'],
                          selected: _temperatureUnit,
                          onSelected: (value) {
                            setState(() => _temperatureUnit = value);
                          },
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.schedule_rounded,
                        title: 'Time Format',
                        subtitle: _timeFormat,
                        trailing: _SegmentedChoice(
                          values: const ['12-Hour', '24-Hour'],
                          selected: _timeFormat,
                          onSelected: (value) {
                            setState(() => _timeFormat = value);
                          },
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Preferences',
                        subtitle: _notificationSubtitle,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: _showNotificationPreferences,
                      ),
                      _SettingRow(
                        icon: Icons.volume_up_outlined,
                        title: 'Sound Effects',
                        subtitle: 'Play sounds for actions and alerts',
                        trailing: Switch(
                          value: _soundEffects,
                          onChanged: (value) {
                            setState(() => _soundEffects = value);
                          },
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.speaker_rounded,
                        title: 'Voice Assistants & Alexa',
                        subtitle: 'Amazon Alexa, Google Home & Siri',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const IntegrationsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingRow(
                        icon: Icons.grid_view_rounded,
                        title: 'Widget Settings',
                        subtitle: 'Customize your dashboard widgets',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => _showInfo(
                          'Widget Settings',
                          'Dashboard widgets continue to use your live property, device, energy and safety data.',
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    icon: Icons.memory_rounded,
                    title: 'System Settings',
                    children: [
                      _SettingRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Security & Privacy',
                        subtitle: 'Manage security, permissions and privacy',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingRow(
                        icon: Icons.storage_rounded,
                        title: 'Data & Storage',
                        subtitle: 'Manage local data and storage usage',
                        onTap: () => _showInfo(
                          'Data & Storage',
                          'Hasomi manages local cache and application data automatically. Your live home data remains controlled by the configured backend services.',
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Backup & Restore',
                        subtitle: 'Backup your data and restore when needed',
                        onTap: () => _showInfo(
                          'Backup & Restore',
                          'No separate user-triggered backup service is configured in this build yet.',
                        ),
                      ),
                      _SettingRow(
                        icon: Icons.sync_rounded,
                        title: 'System Updates',
                        subtitle: 'Check for the latest updates',
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _VersionBadge(text: 'v1.0.0'),
                            SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        onTap: () => _showInfo(
                          'System Updates',
                          'Current app version: 1.0.0+1. App updates are installed through your normal deployment or app distribution channel.',
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    icon: Icons.help_outline_rounded,
                    title: 'Support & About',
                    children: [
                      _SettingRow(
                        icon: Icons.support_agent_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ServicesScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About Hasomi',
                        subtitle: 'App information and terms',
                        onTap: () => _showInfo(
                          'About Hasomi',
                          'Hasomi brings properties, connected devices, automations, energy, water and safety monitoring into one interface.',
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HelpCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ServicesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    icon: Icons.person_outline_rounded,
                    title: 'Account',
                    children: [
                      _SettingRow(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.danger,
                        title: 'Log Out',
                        titleColor: AppColors.danger,
                        subtitle: 'Sign out of this Hasomi account',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.danger,
                        ),
                        onTap: _logout,
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _notificationSubtitle {
    if (!_pushEnabled && !_emailAlerts) return 'Notifications disabled';
    if (_criticalOnly) return 'Critical alerts only';
    if (_pushEnabled && _emailAlerts) return 'Push and email alerts enabled';
    return _pushEnabled ? 'Push notifications enabled' : 'Email alerts enabled';
  }

  void _chooseLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                for (final language in const ['English', 'Hindi'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      language,
                      style: TextStyle(
                        fontWeight: _language == language
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: _language == language
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            color: AppColors.textFaint,
                          ),
                    onTap: () {
                      setState(() => _language = language);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback onMenu;
  final VoidCallback onAlerts;

  const _SettingsHeader({
    required this.alertCount,
    required this.onMenu,
    required this.onAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 21,
                color: AppColors.textPrimary,
              ),
            ),
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, size: 28),
            color: AppColors.textPrimary,
          ),
          const Spacer(),
          const Column(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Customize your Hasomi experience',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onAlerts,
                icon: const Icon(Icons.notifications_none_rounded, size: 29),
                color: AppColors.textPrimary,
              ),
              if (alertCount > 0)
                Positioned(
                  top: 3,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6F0EC)),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            width: 175,
            height: 195,
            child: Image.asset(
              'assets/images/new_robot.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 150, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make Hasomi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const Text(
                  'your own ✦',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Adjust preferences and control how your system works.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primary,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Your data is safe with us',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(
                      alpha: 0.09,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ] else if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: AppColors.divider),
      ],
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SegmentedChoice({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((value) {
          final isSelected = selected == value;
          return InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChevronValue extends StatelessWidget {
  final String value;

  const _ChevronValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String text;

  const _VersionBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HelpCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9F1ED)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/smart_robot.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "We're here to make your home smarter.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Chat with Hasomi'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
