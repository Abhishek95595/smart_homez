import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/automation_model.dart';
import '../../providers/automation_provider.dart';
import '../../theme/app_theme.dart';
import 'create_automation_screen.dart';

class AutomationDetailsScreen extends StatefulWidget {
  final AutomationModel rule;

  const AutomationDetailsScreen({super.key, required this.rule});

  @override
  State<AutomationDetailsScreen> createState() =>
      _AutomationDetailsScreenState();
}

class _DetailActionItem {
  final String deviceName;
  final String deviceType;
  final String stateDisplay;

  const _DetailActionItem({
    required this.deviceName,
    required this.deviceType,
    required this.stateDisplay,
  });
}

class _AutomationDetailsScreenState extends State<AutomationDetailsScreen> {
  late bool _isEnabled;
  late AutomationModel _currentRule;

  @override
  void initState() {
    super.initState();
    _currentRule = widget.rule;
    _isEnabled = widget.rule.isActive;
  }

  String _getSubtitle(String name) {
    if (_currentRule.description != null &&
        _currentRule.description!.trim().isNotEmpty) {
      final desc = _currentRule.description!.trim();
      if (!desc.contains('Light') &&
          !desc.contains('Fan') &&
          !desc.contains('ON')) {
        return desc;
      }
    }
    final lower = name.toLowerCase();
    if (lower.contains('morning') || lower.contains('sunrise')) {
      return 'Your home gets ready for the day automatically.';
    }
    if (lower.contains('movie') || lower.contains('cinema')) {
      return 'Dim lights, turn on entertainment, and set cozy ambiance.';
    }
    if (lower.contains('night') || lower.contains('sleep')) {
      return 'Turns off devices and secures your home for bedtime.';
    }
    if (lower.contains('away') || lower.contains('leave')) {
      return 'Secures your home and powers down appliances when away.';
    }
    return 'Automates your connected home devices with one smart routine.';
  }

  String _getTriggerTime(AutomationModel rule) {
    for (final condition in rule.conditions) {
      final value = condition.timeValue;
      if (value != null && value.trim().isNotEmpty) {
        return _formatTime12Hour(value.trim());
      }
    }
    final name = rule.name.toLowerCase();
    if (name.contains('morning')) return '7:00 AM';
    if (name.contains('movie')) return '7:30 PM';
    if (name.contains('night')) return '10:30 PM';
    return '7:00 AM';
  }

  static String _formatTime12Hour(String timeStr) {
    if (timeStr.contains('AM') || timeStr.contains('PM')) return timeStr;
    final parts = timeStr.split(':');
    if (parts.isEmpty) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final isPm = hour >= 12;
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';
    return '$formattedHour:$formattedMinute $period';
  }

  List<_DetailActionItem> _getActions(AutomationModel rule) {
    final List<_DetailActionItem> items = [];
    if (rule.actions.isNotEmpty) {
      for (final a in rule.actions) {
        final summary = a.commandValue ?? a.command ?? 'ON';
        items.add(
          _DetailActionItem(
            deviceName: a.commandValue?.split(' ').first ?? 'Smart Device',
            deviceType: _deduceType(a.commandValue ?? a.command ?? ''),
            stateDisplay: summary,
          ),
        );
      }
    }

    if (items.isEmpty) {
      final name = rule.name.toLowerCase();
      if (name.contains('morning')) {
        items.addAll([
          const _DetailActionItem(
            deviceName: 'Bedroom Light',
            deviceType: 'light',
            stateDisplay: 'ON',
          ),
          const _DetailActionItem(
            deviceName: 'Fan',
            deviceType: 'fan',
            stateDisplay: 'Speed 2',
          ),
          const _DetailActionItem(
            deviceName: 'Living Room Light',
            deviceType: 'lamp',
            stateDisplay: '70%',
          ),
        ]);
      } else if (name.contains('movie')) {
        items.addAll([
          const _DetailActionItem(
            deviceName: 'Living Room Light',
            deviceType: 'lamp',
            stateDisplay: '20%',
          ),
          const _DetailActionItem(
            deviceName: 'TV',
            deviceType: 'tv',
            stateDisplay: 'ON',
          ),
          const _DetailActionItem(
            deviceName: 'Curtains',
            deviceType: 'curtain',
            stateDisplay: 'Close',
          ),
        ]);
      } else if (name.contains('night')) {
        items.addAll([
          const _DetailActionItem(
            deviceName: 'All Lights',
            deviceType: 'light',
            stateDisplay: 'OFF',
          ),
          const _DetailActionItem(
            deviceName: 'Fan',
            deviceType: 'fan',
            stateDisplay: 'OFF',
          ),
          const _DetailActionItem(
            deviceName: 'Door Lock',
            deviceType: 'lock',
            stateDisplay: 'ON',
          ),
        ]);
      } else {
        items.addAll([
          const _DetailActionItem(
            deviceName: 'Living Room Light',
            deviceType: 'light',
            stateDisplay: 'ON',
          ),
          const _DetailActionItem(
            deviceName: 'Fan',
            deviceType: 'fan',
            stateDisplay: 'Speed 3',
          ),
        ]);
      }
    }
    return items;
  }

  static String _deduceType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('fan')) return 'fan';
    if (lower.contains('lamp') || lower.contains('living')) return 'lamp';
    if (lower.contains('tv')) return 'tv';
    if (lower.contains('lock')) return 'lock';
    if (lower.contains('curtain')) return 'curtain';
    return 'light';
  }

  Future<void> _toggleAutomation(bool newValue) async {
    setState(() => _isEnabled = newValue);
    final provider = context.read<AutomationProvider>();
    await provider.toggleRule(
      automationId: _currentRule.id,
      isActive: newValue,
    );
  }

  Future<void> _deleteAutomation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete automation?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('“${_currentRule.name}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<AutomationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.deleteRule(_currentRule.id);

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Automation deleted.')),
    );
    Navigator.pop(context);
  }

  Future<void> _editAutomation() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateAutomationScreen(existingRule: _currentRule),
      ),
    );
    if (!mounted) return;
    // Refresh rule from provider
    final updated = context
        .read<AutomationProvider>()
        .rules
        .where((r) => r.id == _currentRule.id)
        .firstOrNull;
    if (updated != null) {
      setState(() {
        _currentRule = updated;
        _isEnabled = updated.isActive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _getActions(_currentRule);
    final heroTheme = _getHeroVisualTheme(_currentRule.name);
    final triggerTime = _getTriggerTime(_currentRule);
    final subtitle = _getSubtitle(_currentRule.name);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFD),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: Color(0xFF0F172A),
                    ),
                    tooltip: 'Back',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') _editAutomation();
                      if (val == 'delete') _deleteAutomation();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  // 1. Hero Automation Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big Themed Icon Box
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: heroTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: heroTheme.iconWidget,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentRule.name,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isEnabled
                                    ? const Color(0xFFE8F8F5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.5,
                                    height: 6.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isEnabled
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isEnabled ? 'Active' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _isEnabled
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Trigger Card
                  _DetailsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _DetailsIconBox(icon: Icons.access_time_rounded),
                            SizedBox(width: 12),
                            Text(
                              'Trigger',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Every day · $triggerTime',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Actions Card
                  _DetailsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _DetailsIconBox(icon: Icons.bolt_rounded),
                            const SizedBox(width: 12),
                            Text(
                              'Actions (${actions.length})',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action rows
                        ...actions.map((act) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              children: [
                                _ActionBadgeIcon(type: act.deviceType),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    act.deviceName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      act.stateDisplay,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        // Notice Banner: "Only the home owner can change this automation."
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCCFBF1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                color: Color(0xFF00897B),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Only the home owner can change this automation.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Enable Automation Switch Card
                  _DetailsCard(
                    child: Row(
                      children: [
                        const Text(
                          'Enable Automation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _toggleAutomation(!_isEnabled),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 48,
                            height: 28,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _isEnabled
                                  ? const Color(0xFF00897B)
                                  : const Color(0xFFCBD5E1),
                            ),
                            alignment: _isEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x24000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 5. Bottom Edit & Delete Buttons Row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Edit Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF00897B),
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _editAutomation,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF00897B),
                          size: 18,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFF00897B),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Delete Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFCA5A5),
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _deleteAutomation,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _HeroTheme _getHeroVisualTheme(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('morning') ||
        lower.contains('sunrise') ||
        lower.contains('wakeup')) {
      return _HeroTheme(
        backgroundColor: const Color(0xFFFFF7ED),
        iconWidget: const Icon(
          Icons.wb_sunny_rounded,
          color: Color(0xFFF59E0B),
          size: 38,
        ),
      );
    }
    if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('tv')) {
      return _HeroTheme(
        backgroundColor: const Color(0xFFF3E8FF),
        iconWidget: const Icon(
          Icons.theaters_rounded,
          color: Color(0xFF7C3AED),
          size: 36,
        ),
      );
    }
    if (lower.contains('night') || lower.contains('sleep')) {
      return _HeroTheme(
        backgroundColor: const Color(0xFFE0E7FF),
        iconWidget: const Icon(
          Icons.nights_stay_rounded,
          color: Color(0xFF1E3A8A),
          size: 36,
        ),
      );
    }
    return _HeroTheme(
      backgroundColor: const Color(0xFFE6F7F5),
      iconWidget: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF00897B),
        size: 36,
      ),
    );
  }
}

class _HeroTheme {
  final Color backgroundColor;
  final Widget iconWidget;

  const _HeroTheme({required this.backgroundColor, required this.iconWidget});
}

class _DetailsCard extends StatelessWidget {
  final Widget child;

  const _DetailsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailsIconBox extends StatelessWidget {
  final IconData icon;

  const _DetailsIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF00897B), size: 20),
    );
  }
}

class _ActionBadgeIcon extends StatelessWidget {
  final String type;

  const _ActionBadgeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFFFFBEB);
    Color iconColor = const Color(0xFFF59E0B);
    IconData icon = Icons.lightbulb_outline_rounded;

    if (type == 'fan') {
      bg = const Color(0xFFE6F7F5);
      iconColor = const Color(0xFF00897B);
      icon = Icons.toys_outlined;
    } else if (type == 'lamp') {
      bg = const Color(0xFFF3E8FF);
      iconColor = const Color(0xFF7C3AED);
      icon = Icons.tungsten_rounded;
    } else if (type == 'tv') {
      bg = const Color(0xFFEDE9FE);
      iconColor = const Color(0xFF6D28D9);
      icon = Icons.tv_rounded;
    } else if (type == 'curtain') {
      bg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.curtains_rounded;
    } else if (type == 'lock') {
      bg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.lock_outline_rounded;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
