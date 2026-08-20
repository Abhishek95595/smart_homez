import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/requests/create_automation_request.dart';
import '../../models/automation_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/automation_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_state_widgets.dart';
import '../alerts/alerts_screen.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  _AutomationSection _section = _AutomationSection.all;
  String? _selectedHomeId;
  final Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AutomationProvider>().fetchRules();
      }
    });
  }

  Future<void> _addAutomation({_AutomationDraft? draft}) async {
    final result = await showModalBottomSheet<_AutomationDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AutomationForm(draft: draft),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.addRule(
      CreateAutomationRequest(name: result.name, isActive: true),
    );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Automation created.' : 'Unable to create automation.',
        ),
      ),
    );
  }

  Future<void> _editAutomation(AutomationModel rule) async {
    final result = await showModalBottomSheet<_AutomationDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AutomationForm(
        isEditing: true,
        draft: _AutomationDraft(
          name: rule.name,
          trigger: _triggerTime(rule),
          action: rule.description ?? _actionSummary(rule),
          repeat: _repeatSummary(rule),
          scene: _sceneName(rule),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.updateRule(
      automationId: rule.id,
      request: CreateAutomationRequest(
        name: result.name,
        isActive: rule.isActive,
      ),
    );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Automation updated.' : 'Unable to update automation.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AutomationModel rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete automation?'),
        content: Text('“${rule.name}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.deleteRule(rule.id);
    if (!mounted) return;

    setState(() => _favoriteIds.remove(rule.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Automation deleted.' : 'Unable to delete automation.',
        ),
      ),
    );
  }

  Future<void> _showAutomationDetails(AutomationModel rule) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final fullRule = await context.read<AutomationProvider>().getAutomation(
        rule.id,
      );
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AutomationDetailsSheet(rule: fullRule),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load details: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _showAutomationHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ask Homez',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a simple trigger and action. Homez can help you turn it into a useful routine.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            const _HelpTip(
              icon: Icons.schedule_rounded,
              title: 'Scheduled',
              text: 'Run lights, AC, curtains, or scenes at a chosen time.',
            ),
            const _HelpTip(
              icon: Icons.sensors_rounded,
              title: 'Sensor based',
              text: 'Use a device or sensor change as the trigger.',
            ),
            const _HelpTip(
              icon: Icons.auto_awesome_rounded,
              title: 'Scene based',
              text: 'Group several device actions into one routine.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addAutomation();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create automation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sceneName(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('morning') || name.contains('sunrise')) return 'Morning';
    if (name.contains('night') || name.contains('sleep')) return 'Night';
    if (name.contains('away') || name.contains('leave')) return 'Away';
    if (name.contains('movie')) return 'Movie';

    if (rule.conditions.any((c) => c.timeValue?.contains('08:00') == true)) {
      return 'Morning';
    }
    if (rule.conditions.any((c) => c.timeValue?.contains('22:00') == true)) {
      return 'Night';
    }
    return 'Custom';
  }

  static String _triggerTime(AutomationModel rule) {
    for (final condition in rule.conditions) {
      final value = condition.timeValue;
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return '08:00';
  }

  static String _repeatSummary(AutomationModel rule) {
    if (rule.conditions.any((c) => c.timeValue?.trim().isNotEmpty == true)) {
      return 'Daily';
    }
    return 'Custom';
  }

  static String _actionSummary(AutomationModel rule) {
    if (rule.actions.isEmpty) {
      return rule.description ?? 'Run automation';
    }
    final command = rule.actions.first.command?.trim();
    return command?.isNotEmpty == true ? command! : 'Run automation';
  }

  List<AutomationModel> _scheduledRules(List<AutomationModel> rules) {
    return rules
        .where(
          (rule) => rule.conditions.any(
            (condition) => condition.timeValue?.trim().isNotEmpty == true,
          ),
        )
        .toList();
  }

  bool _show(_AutomationSection section) {
    return _section == _AutomationSection.all || _section == section;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();
    final alertCount = context.watch<AlertProvider>().criticalActiveCount;
    final properties = context.watch<PropertyProvider>().properties;
    final scheduled = _scheduledRules(provider.rules);

    String? effectiveHomeId = _selectedHomeId;
    if (properties.isNotEmpty &&
        !properties.any((property) => property.id == effectiveHomeId)) {
      effectiveHomeId = properties.first.id;
    }

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: const Color(0xFFFBFDFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AutomationHeader(
              alertCount: alertCount,
              onAlerts: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
              },
            ),
            Expanded(
              child: provider.isLoading && provider.rules.isEmpty
                  ? const AppLoadingState(message: 'Loading automations…')
                  : RefreshIndicator(
                      onRefresh: provider.fetchRules,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 5, 14, 26),
                        children: [
                          _TopControls(
                            properties: properties
                                .map(
                                  (property) => _HomeChoice(
                                    id: property.id,
                                    name: property.name,
                                  ),
                                )
                                .toList(),
                            selectedHomeId: effectiveHomeId,
                            selectedSection: _section,
                            onHomeChanged: (id) {
                              setState(() => _selectedHomeId = id);
                            },
                            onSectionChanged: (section) {
                              setState(() => _section = section);
                            },
                            onCreate: () => _addAutomation(),
                          ),
                          const SizedBox(height: 14),
                          _AutomationHero(
                            onExplore: () {
                              setState(
                                () => _section = _AutomationSection.scenes,
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _AutomationSectionBar(
                            selected: _section,
                            onSelected: (section) {
                              setState(() => _section = section);
                            },
                          ),
                          const SizedBox(height: 17),
                          if (provider.errorMessage != null) ...[
                            _AutomationErrorBanner(
                              message: provider.errorMessage!,
                              onRetry: provider.fetchRules,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_show(_AutomationSection.scenes)) ...[
                            _MyScenesSection(
                              onApply: (draft) => _addAutomation(draft: draft),
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_show(_AutomationSection.rules)) ...[
                            _AutomationRulesSection(
                              rules: provider.rules,
                              favoriteIds: _favoriteIds,
                              onEdit: _editAutomation,
                              onDelete: _confirmDelete,
                              onView: _showAutomationDetails,
                              onFavorite: (rule) {
                                setState(() {
                                  if (_favoriteIds.contains(rule.id)) {
                                    _favoriteIds.remove(rule.id);
                                  } else {
                                    _favoriteIds.add(rule.id);
                                  }
                                });
                              },
                              onAdd: () => _addAutomation(),
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_show(_AutomationSection.schedules)) ...[
                            _ScheduledAutomationsSection(
                              rules: scheduled,
                              onTapRule: _showAutomationDetails,
                              onAdd: () => _addAutomation(
                                draft: const _AutomationDraft(
                                  name: 'New Schedule',
                                  trigger: '08:00',
                                  action: 'Run scheduled devices',
                                  repeat: 'Daily',
                                  scene: 'Custom',
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_show(_AutomationSection.timers)) ...[
                            _TimersPanel(
                              onAdd: () => _addAutomation(
                                draft: const _AutomationDraft(
                                  name: 'New Timer',
                                  trigger: '08:00',
                                  action: 'Turn device off after timer',
                                  repeat: 'Custom',
                                  scene: 'Custom',
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          _QuickActions(
                            onCreateRule: () => _addAutomation(),
                            onCreateScene: () => _addAutomation(
                              draft: const _AutomationDraft(
                                name: 'New Scene',
                                trigger: '08:00',
                                action: 'Run scene devices',
                                repeat: 'Custom',
                                scene: 'Custom',
                              ),
                            ),
                            onAddSchedule: () => _addAutomation(
                              draft: const _AutomationDraft(
                                name: 'New Schedule',
                                trigger: '08:00',
                                action: 'Run scheduled devices',
                                repeat: 'Daily',
                                scene: 'Custom',
                              ),
                            ),
                            onAddTimer: () => _addAutomation(
                              draft: const _AutomationDraft(
                                name: 'New Timer',
                                trigger: '08:00',
                                action: 'Turn device off after timer',
                                repeat: 'Custom',
                                scene: 'Custom',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AutomationHelpBanner(onTap: _showAutomationHelp),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AutomationSection { all, scenes, schedules, rules, timers }

extension on _AutomationSection {
  String get label => switch (this) {
    _AutomationSection.all => 'All Automations',
    _AutomationSection.scenes => 'Scenes',
    _AutomationSection.schedules => 'Schedules',
    _AutomationSection.rules => 'Rules',
    _AutomationSection.timers => 'Timers',
  };

  IconData get icon => switch (this) {
    _AutomationSection.all => Icons.hub_outlined,
    _AutomationSection.scenes => Icons.wb_twilight_outlined,
    _AutomationSection.schedules => Icons.calendar_month_outlined,
    _AutomationSection.rules => Icons.account_tree_outlined,
    _AutomationSection.timers => Icons.schedule_outlined,
  };
}

class _AutomationHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback onAlerts;

  const _AutomationHeader({required this.alertCount, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        child: SizedBox(
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, size: 30),
                  color: AppColors.textPrimary,
                ),
              ),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Automations',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 27,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Make your home smarter. Automate with ease.',
                    style: TextStyle(
                      color: Color(0xFF26345B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onAlerts,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 29,
                      ),
                      color: AppColors.textPrimary,
                    ),
                    if (alertCount > 0)
                      Positioned(
                        top: 3,
                        right: 3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeChoice {
  final String id;
  final String name;

  const _HomeChoice({required this.id, required this.name});
}

class _TopControls extends StatelessWidget {
  final List<_HomeChoice> properties;
  final String? selectedHomeId;
  final _AutomationSection selectedSection;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<_AutomationSection> onSectionChanged;
  final VoidCallback onCreate;

  const _TopControls({
    required this.properties,
    required this.selectedHomeId,
    required this.selectedSection,
    required this.onHomeChanged,
    required this.onSectionChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Column(
          children: [
            Row(
              children: [
                const Text(
                  'Select Home',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _HomeSelector(
                    properties: properties,
                    selectedHomeId: selectedHomeId,
                    onChanged: onHomeChanged,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 15),
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _SectionSelector(
                      selected: selectedSection,
                      onSelected: onSectionChanged,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (compact) ...[
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SectionSelector(
                      selected: selectedSection,
                      onSelected: onSectionChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const Spacer(),
                SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create New'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HomeSelector extends StatelessWidget {
  final List<_HomeChoice> properties;
  final String? selectedHomeId;
  final ValueChanged<String?> onChanged;

  const _HomeSelector({
    required this.properties,
    required this.selectedHomeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return _ControlPill(
        icon: Icons.home_outlined,
        label: 'My Home',
        trailing: Icons.keyboard_arrow_down_rounded,
        onTap: null,
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedHomeId,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: properties
              .map(
                (property) => DropdownMenuItem<String>(
                  value: property.id,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          property.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionSelector extends StatelessWidget {
  final _AutomationSection selected;
  final ValueChanged<_AutomationSection> onSelected;

  const _SectionSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AutomationSection>(
      tooltip: 'Filter automations',
      onSelected: onSelected,
      itemBuilder: (_) => _AutomationSection.values
          .map(
            (section) => PopupMenuItem(
              value: section,
              child: Row(
                children: [
                  Icon(section.icon, size: 19, color: AppColors.primaryDark),
                  const SizedBox(width: 9),
                  Text(section.label),
                ],
              ),
            ),
          )
          .toList(),
      child: _ControlPill(
        icon: Icons.grid_view_rounded,
        label: selected.label,
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
    );
  }
}

class _ControlPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData trailing;
  final VoidCallback? onTap;

  const _ControlPill({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(trailing, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }
}

class _AutomationHero extends StatelessWidget {
  final VoidCallback onExplore;

  const _AutomationHero({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3F0ED)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                right: -22,
                bottom: -10,
                width: constraints.maxWidth * 0.62,
                height: 215,
                child: Opacity(
                  opacity: 0.96,
                  child: Image.asset(
                    'assets/images/home_hero_reference.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              const Positioned(
                top: 20,
                right: 14,
                child: _HeroFeatureBubble(
                  icon: Icons.lightbulb_outline_rounded,
                ),
              ),
              const Positioned(
                top: 67,
                right: 8,
                child: _HeroFeatureBubble(icon: Icons.videocam_outlined),
              ),
              const Positioned(
                bottom: 18,
                right: 16,
                child: _HeroFeatureBubble(icon: Icons.water_drop_outlined),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  20,
                  (constraints.maxWidth * 0.54).clamp(180.0, 285.0).toDouble(),
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Let Homez\ntake care of the rest!',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Save time, save energy,\nand live worry-free.',
                      style: TextStyle(
                        color: Color(0xFF26345B),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: onExplore,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        label: const Text('Explore Smart Scenes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          backgroundColor: Colors.white.withValues(alpha: 0.88),
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroFeatureBubble extends StatelessWidget {
  final IconData icon;

  const _HeroFeatureBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD8ECE8)),
      ),
      child: Icon(icon, size: 19, color: AppColors.primaryDark),
    );
  }
}

class _AutomationSectionBar extends StatelessWidget {
  final _AutomationSection selected;
  final ValueChanged<_AutomationSection> onSelected;

  const _AutomationSectionBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _AutomationSection.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final section = _AutomationSection.values[index];
          final active = selected == section;
          return InkWell(
            onTap: () => onSelected(section),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: active ? AppColors.brandGradient : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    section.icon,
                    size: 18,
                    color: active ? Colors.white : const Color(0xFF26345B),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    section.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: active ? Colors.white : const Color(0xFF26345B),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Color(0xFF26345B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: Color(0xFF26345B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MyScenesSection extends StatelessWidget {
  final ValueChanged<_AutomationDraft> onApply;

  const _MyScenesSection({required this.onApply});

  @override
  Widget build(BuildContext context) {
    const scenes = <_SceneCardData>[
      _SceneCardData(
        title: 'Morning',
        actions: 4,
        image: 'assets/images/scene_morning.png',
        draft: _AutomationDraft(
          name: 'Morning Scene',
          trigger: '06:00',
          action: 'Turn on morning devices',
          repeat: 'Daily',
          scene: 'Morning',
        ),
      ),
      _SceneCardData(
        title: 'Night',
        actions: 5,
        image: 'assets/images/scene_night.png',
        draft: _AutomationDraft(
          name: 'Night Scene',
          trigger: '22:00',
          action: 'Dim lights and secure the home',
          repeat: 'Daily',
          scene: 'Night',
        ),
      ),
      _SceneCardData(
        title: 'Away',
        actions: 6,
        image: 'assets/images/scene_away.png',
        draft: _AutomationDraft(
          name: 'Away Mode',
          trigger: '09:00',
          action: 'Turn off devices and secure the home',
          repeat: 'Custom',
          scene: 'Away',
        ),
      ),
      _SceneCardData(
        title: 'Movie Time',
        actions: 3,
        image: 'assets/images/scene_movie.png',
        draft: _AutomationDraft(
          name: 'Movie Time',
          trigger: '20:00',
          action: 'Dim lights and activate movie mode',
          repeat: 'Custom',
          scene: 'Custom',
        ),
      ),
      _SceneCardData(
        title: 'Party',
        actions: 7,
        icon: Icons.celebration_rounded,
        draft: _AutomationDraft(
          name: 'Party Scene',
          trigger: '19:00',
          action: 'Activate party lights and music',
          repeat: 'Custom',
          scene: 'Custom',
        ),
      ),
    ];

    return Column(
      children: [
        const _SectionTitle(title: 'My Scenes', actionLabel: 'View All'),
        const SizedBox(height: 9),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: scenes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final scene = scenes[index];
              return _SceneCard(
                scene: scene,
                onPlay: () => onApply(scene.draft),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SceneCardData {
  final String title;
  final int actions;
  final String? image;
  final IconData? icon;
  final _AutomationDraft draft;

  const _SceneCardData({
    required this.title,
    required this.actions,
    required this.draft,
    this.image,
    this.icon,
  });
}

class _SceneCard extends StatelessWidget {
  final _SceneCardData scene;
  final VoidCallback onPlay;

  const _SceneCard({required this.scene, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 92,
            width: double.infinity,
            child: scene.image != null
                ? Image.asset(scene.image!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD7E8), Color(0xFFDCC9FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      scene.icon ?? Icons.auto_awesome_rounded,
                      size: 44,
                      color: const Color(0xFF8B4BB4),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${scene.actions} Actions',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onPlay,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 19,
                      color: AppColors.primary,
                    ),
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

class _AutomationRulesSection extends StatelessWidget {
  final List<AutomationModel> rules;
  final Set<String> favoriteIds;
  final ValueChanged<AutomationModel> onEdit;
  final ValueChanged<AutomationModel> onDelete;
  final ValueChanged<AutomationModel> onView;
  final ValueChanged<AutomationModel> onFavorite;
  final VoidCallback onAdd;

  const _AutomationRulesSection({
    required this.rules,
    required this.favoriteIds,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.onFavorite,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final displayed = rules.take(6).toList();
    return Column(
      children: [
        _SectionTitle(
          title: 'Automation Rules',
          actionLabel: 'View All',
          onAction: () {},
        ),
        const SizedBox(height: 8),
        if (displayed.isEmpty)
          _CompactEmptyState(onAdd: onAdd)
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(displayed.length, (index) {
                final rule = displayed[index];
                return Column(
                  children: [
                    _AutomationRuleRow(
                      rule: rule,
                      isFavorite: favoriteIds.contains(rule.id),
                      onEdit: () => onEdit(rule),
                      onDelete: () => onDelete(rule),
                      onView: () => onView(rule),
                      onFavorite: () => onFavorite(rule),
                    ),
                    if (index != displayed.length - 1)
                      const Divider(height: 1, indent: 54),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _AutomationRuleRow extends StatelessWidget {
  final AutomationModel rule;
  final bool isFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final VoidCallback onFavorite;

  const _AutomationRuleRow({
    required this.rule,
    required this.isFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();
    final isUpdating = provider.isRuleUpdating(rule.id);
    final accent = _accentForRule(rule);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 4, 9),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.11),
                ),
                child: Icon(_iconForRule(rule), size: 20, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ruleSubtitle(rule),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.8,
                        color: Color(0xFF34446A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpdating)
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: rule.isActive,
                    onChanged: (value) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await provider.toggleRule(
                        automationId: rule.id,
                        isActive: value,
                      );
                      if (!success && context.mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Unable to update automation.'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Color(0xFF26345B),
                ),
                onSelected: (value) {
                  if (value == 'view') onView();
                  if (value == 'edit') onEdit();
                  if (value == 'favorite') onFavorite();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View details'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Text(
                      isFavorite ? 'Remove favorite' : 'Add to favorites',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ruleSubtitle(AutomationModel rule) {
    for (final condition in rule.conditions) {
      final time = condition.timeValue?.trim();
      if (time != null && time.isNotEmpty) return 'At $time  •  Daily';

      final property = condition.propertyName?.trim();
      final value = condition.expectedValue?.trim();
      if (property != null && property.isNotEmpty) {
        return value?.isNotEmpty == true
            ? 'When $property ${condition.operator ?? ''} $value'
            : 'When $property changes';
      }
    }
    return rule.description?.trim().isNotEmpty == true
        ? rule.description!.trim()
        : 'Smart automation rule';
  }

  static IconData _iconForRule(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('light')) return Icons.light_mode_outlined;
    if (name.contains('ac') || name.contains('temperature')) {
      return Icons.device_thermostat_rounded;
    }
    if (name.contains('water') || name.contains('pump')) {
      return Icons.water_drop_outlined;
    }
    if (name.contains('security') || name.contains('arm')) {
      return Icons.shield_outlined;
    }
    if (name.contains('night')) return Icons.nightlight_outlined;
    return Icons.auto_awesome_rounded;
  }

  static Color _accentForRule(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('light')) return const Color(0xFFF0A11A);
    if (name.contains('ac') || name.contains('temperature')) {
      return const Color(0xFFFF6B6B);
    }
    if (name.contains('water') || name.contains('pump')) {
      return const Color(0xFF2F80ED);
    }
    if (name.contains('security') || name.contains('arm')) {
      return const Color(0xFF7C3AED);
    }
    if (name.contains('night')) return const Color(0xFF7057C7);
    return AppColors.primary;
  }
}

class _CompactEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _CompactEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 7),
          const Text(
            'No automation rules yet',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Rule'),
          ),
        ],
      ),
    );
  }
}

class _ScheduledAutomationsSection extends StatelessWidget {
  final List<AutomationModel> rules;
  final ValueChanged<AutomationModel> onTapRule;
  final VoidCallback onAdd;

  const _ScheduledAutomationsSection({
    required this.rules,
    required this.onTapRule,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionTitle(
          title: 'Scheduled Automations',
          actionLabel: 'View Calendar',
          onAction: () {},
        ),
        const SizedBox(height: 8),
        if (rules.isEmpty)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_alarm_rounded, color: AppColors.primary),
                  SizedBox(height: 5),
                  Text(
                    'Add a scheduled automation',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: rules.take(6).length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _ScheduleCard(rule: rule, onTap: () => onTapRule(rule));
              },
            ),
          ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final AutomationModel rule;
  final VoidCallback onTap;

  const _ScheduleCard({required this.rule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = _AutomationsScreenState._triggerTime(rule);
    final scene = _AutomationsScreenState._sceneName(rule);
    final icon = switch (scene) {
      'Morning' => Icons.wb_sunny_outlined,
      'Night' => Icons.nightlight_outlined,
      'Away' => Icons.energy_savings_leaf_outlined,
      _ => Icons.schedule_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 154,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Daily',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF34446A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              rule.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${rule.actions.isEmpty ? 1 : rule.actions.length} Actions',
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimersPanel extends StatelessWidget {
  final VoidCallback onAdd;

  const _TimersPanel({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(title: 'Timers', actionLabel: 'View All'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a device timer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Automatically turn a device on or off after a duration.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onCreateRule;
  final VoidCallback onCreateScene;
  final VoidCallback onAddSchedule;
  final VoidCallback onAddTimer;

  const _QuickActions({
    required this.onCreateRule,
    required this.onCreateScene,
    required this.onAddSchedule,
    required this.onAddTimer,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.add_circle_outline_rounded,
        label: 'Create New Rule',
        onTap: onCreateRule,
      ),
      _QuickActionData(
        icon: Icons.wb_twilight_outlined,
        label: 'Create Scene',
        onTap: onCreateScene,
      ),
      _QuickActionData(
        icon: Icons.calendar_month_outlined,
        label: 'Add Schedule',
        onTap: onAddSchedule,
      ),
      _QuickActionData(
        icon: Icons.timer_outlined,
        label: 'Add Timer',
        onTap: onAddTimer,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 9) / 2;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      height: 47,
                      child: OutlinedButton.icon(
                        onPressed: item.onTap,
                        icon: Icon(item.icon, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(item.label),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _AutomationHelpBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AutomationHelpBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCF0EC)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 84,
            child: Image.asset(
              'assets/images/smart_robot.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with automations?',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ask Homez to create custom automations based on your routine.',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF34446A),
                    fontSize: 9.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Ask Homez'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AutomationErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDADA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HelpTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpTip({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
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

class _AutomationDetailsSheet extends StatelessWidget {
  final AutomationModel rule;

  const _AutomationDetailsSheet({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              rule.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (rule.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                rule.description!.trim(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Conditions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (rule.conditions.isEmpty)
              const Text(
                'No trigger conditions configured.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...rule.conditions.map(
                (c) => _DetailRow(
                  icon: Icons.schedule_rounded,
                  text:
                      '${c.conditionType ?? 'Condition'}: ${c.propertyName ?? ''} ${c.operator ?? ''} ${c.expectedValue ?? c.timeValue ?? ''}',
                ),
              ),
            const SizedBox(height: 18),
            const Text(
              'Actions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (rule.actions.isEmpty)
              const Text(
                'No device actions configured.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...rule.actions.map(
                (a) => _DetailRow(
                  icon: Icons.bolt_rounded,
                  text:
                      '${a.actionType ?? 'Action'}: ${a.command ?? ''} ${a.commandValue ?? ''}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.trim(),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationForm extends StatefulWidget {
  final _AutomationDraft? draft;
  final bool isEditing;

  const _AutomationForm({this.draft, this.isEditing = false});

  @override
  State<_AutomationForm> createState() => _AutomationFormState();
}

class _AutomationFormState extends State<_AutomationForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _action;
  late String _trigger;
  late String _repeat;
  late String _scene;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft?.name);
    _action = TextEditingController(text: widget.draft?.action);
    _trigger = widget.draft?.trigger ?? '08:00';
    _repeat = widget.draft?.repeat ?? 'Daily';
    _scene = widget.draft?.scene ?? 'Custom';
  }

  @override
  void dispose() {
    _name.dispose();
    _action.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initialParts = _trigger.split(':');
    final initialHour = int.tryParse(initialParts.first) ?? 8;
    final initialMinute = initialParts.length > 1
        ? int.tryParse(initialParts[1]) ?? 0
        : 0;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour.clamp(0, 23).toInt(),
        minute: initialMinute.clamp(0, 59).toInt(),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _trigger =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      _AutomationDraft(
        name: _name.text.trim(),
        trigger: _trigger,
        action: _action.text.trim(),
        repeat: _repeat,
        scene: _scene,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.isEditing ? 'Edit automation' : 'Create automation',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose when it runs and what it should do.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Automation name',
                  hintText: 'e.g. Weekday wake-up',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(18),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  child: Text(_trigger),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                items: const ['Daily', 'Weekdays', 'Weekends', 'Custom']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _repeat = value ?? _repeat),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _scene,
                decoration: const InputDecoration(
                  labelText: 'Scene',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
                items: const ['Morning', 'Night', 'Away', 'Custom']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _scene = value ?? _scene),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _action,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Actions',
                  hintText: 'Turn on hallway lights and set brightness to 40%',
                  prefixIcon: Icon(Icons.bolt_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.trim().length ?? 0) < 4
                    ? 'Describe the action'
                    : null,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                    widget.isEditing ? Icons.save_outlined : Icons.add_rounded,
                  ),
                  label: Text(
                    widget.isEditing ? 'Save changes' : 'Create automation',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomationDraft {
  final String name;
  final String trigger;
  final String action;
  final String repeat;
  final String scene;

  const _AutomationDraft({
    required this.name,
    required this.trigger,
    required this.action,
    required this.repeat,
    required this.scene,
  });
}
