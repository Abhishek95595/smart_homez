import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/requests/create_automation_request.dart';
import '../../models/automation_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/automation_provider.dart';
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
  _AutomationFilter _filter = _AutomationFilter.all;
  _AutomationSort _sort = _AutomationSort.recent;
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
    if (result == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.addRule(
      CreateAutomationRequest(name: result.name, isActive: true),
    );

    if (!mounted) {
      return;
    }
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
    if (result == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.updateRule(
      automationId: rule.id,
      request: CreateAutomationRequest(
        name: result.name,
        isActive: rule.isActive,
      ),
    );

    if (!mounted) {
      return;
    }
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

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.deleteRule(rule.id);
    if (!mounted) {
      return;
    }

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
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AutomationDetailsSheet(rule: fullRule),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
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
              'Automation helper',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start with one trigger and one clear action. You can refine the rule later.',
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
              text: 'Use device state or sensor changes as the trigger.',
            ),
            const _HelpTip(
              icon: Icons.auto_awesome_rounded,
              title: 'Scene based',
              text: 'Group several device actions into a simple routine.',
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

  List<AutomationModel> _visibleRules(List<AutomationModel> allRules) {
    Iterable<AutomationModel> result = allRules;

    switch (_filter) {
      case _AutomationFilter.all:
        break;
      case _AutomationFilter.byRoom:
        result = result.where((rule) {
          final conditionScoped = rule.conditions.any(
            (c) => c.targetDeviceId?.trim().isNotEmpty == true,
          );
          final actionScoped = rule.actions.any(
            (a) => a.targetDeviceId?.trim().isNotEmpty == true,
          );
          return conditionScoped || actionScoped;
        });
        break;
      case _AutomationFilter.scheduled:
        result = result.where(
          (rule) => rule.conditions.any(
            (c) => c.timeValue?.trim().isNotEmpty == true,
          ),
        );
        break;
      case _AutomationFilter.manual:
        result = result.where((rule) => rule.conditions.isEmpty);
        break;
      case _AutomationFilter.favorites:
        result = result.where((rule) => _favoriteIds.contains(rule.id));
        break;
    }

    final rules = result.toList();
    switch (_sort) {
      case _AutomationSort.recent:
        rules.sort((a, b) {
          final ad =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
        break;
      case _AutomationSort.name:
        rules.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case _AutomationSort.activeFirst:
        rules.sort((a, b) {
          if (a.isActive == b.isActive) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return a.isActive ? -1 : 1;
        });
        break;
    }
    return rules;
  }

  static String _sceneName(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('morning') || name.contains('sunrise')) {
      return 'Morning';
    }
    if (name.contains('night') || name.contains('sleep')) {
      return 'Night';
    }
    if (name.contains('away') || name.contains('leave')) {
      return 'Away';
    }
    if (name.contains('movie')) {
      return 'Movie';
    }

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
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
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
    final first = rule.actions.first;
    final command = first.command?.trim();
    if (command != null && command.isNotEmpty) {
      return command;
    }
    return 'Run automation';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();
    final alertCount = context.watch<AlertProvider>().criticalActiveCount;
    final visibleRules = _visibleRules(provider.rules);

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        children: [
                          _AutomationHero(onCreate: () => _addAutomation()),
                          const SizedBox(height: 18),
                          _AutomationFilterBar(
                            selected: _filter,
                            onSelected: (filter) =>
                                setState(() => _filter = filter),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'My Automations (${visibleRules.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<_AutomationSort>(
                                tooltip: 'Sort automations',
                                onSelected: (sort) =>
                                    setState(() => _sort = sort),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: _AutomationSort.recent,
                                    child: Text('Recent'),
                                  ),
                                  PopupMenuItem(
                                    value: _AutomationSort.name,
                                    child: Text('Name'),
                                  ),
                                  PopupMenuItem(
                                    value: _AutomationSort.activeFirst,
                                    child: Text('Active first'),
                                  ),
                                ],
                                child: Row(
                                  children: [
                                    const Text(
                                      'Sort by: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _sort.label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (provider.errorMessage != null) ...[
                            _AutomationErrorBanner(
                              message: provider.errorMessage!,
                              onRetry: provider.fetchRules,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (visibleRules.isEmpty)
                            _EmptyAutomation(
                              filter: _filter,
                              onAdd: () => _addAutomation(),
                            )
                          else
                            ...visibleRules.map(
                              (rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AutomationCard(
                                  rule: rule,
                                  isFavorite: _favoriteIds.contains(rule.id),
                                  onEdit: () => _editAutomation(rule),
                                  onDelete: () => _confirmDelete(rule),
                                  onView: () => _showAutomationDetails(rule),
                                  onFavorite: () {
                                    setState(() {
                                      if (_favoriteIds.contains(rule.id)) {
                                        _favoriteIds.remove(rule.id);
                                      } else {
                                        _favoriteIds.add(rule.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          _SceneSuggestions(
                            onApply: (template) =>
                                _addAutomation(draft: template),
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

enum _AutomationFilter { all, byRoom, scheduled, manual, favorites }

enum _AutomationSort { recent, name, activeFirst }

extension on _AutomationSort {
  String get label => switch (this) {
    _AutomationSort.recent => 'Recent',
    _AutomationSort.name => 'Name',
    _AutomationSort.activeFirst => 'Active',
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
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              icon: const Icon(Icons.menu_rounded, size: 29),
              color: AppColors.textPrimary,
            ),
            const Spacer(),
            const Column(
              children: [
                Text(
                  'Automations',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create smart rules that work for you',
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
                    right: 3,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
          ],
        ),
      ),
    );
  }
}

class _AutomationHero extends StatelessWidget {
  final VoidCallback onCreate;

  const _AutomationHero({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 206,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7F1EC)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -22,
            width: 230,
            height: 230,
            child: Image.asset(
              'assets/images/new_robot.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned(
            top: 22,
            right: 18,
            child: Column(
              children: const [
                _HeroFeatureIcon(icon: Icons.lightbulb_outline_rounded),
                SizedBox(height: 10),
                _HeroFeatureIcon(icon: Icons.device_thermostat_rounded),
                SizedBox(height: 10),
                _HeroFeatureIcon(icon: Icons.health_and_safety_outlined),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 190, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make your\nhome smarter ✦',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Automate your devices and enjoy comfort, savings and peace of mind.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create Automation'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

class _HeroFeatureIcon extends StatelessWidget {
  final IconData icon;

  const _HeroFeatureIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }
}

class _AutomationFilterBar extends StatelessWidget {
  final _AutomationFilter selected;
  final ValueChanged<_AutomationFilter> onSelected;

  const _AutomationFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = <(_AutomationFilter, String)>[
      (_AutomationFilter.all, 'All Automations'),
      (_AutomationFilter.byRoom, 'By Room'),
      (_AutomationFilter.scheduled, 'Scheduled'),
      (_AutomationFilter.manual, 'Manual'),
      (_AutomationFilter.favorites, 'Favorites'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = selected == item.$1;
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onSelected(item.$1),
            showCheckmark: false,
            label: Text(item.$2),
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          );
        },
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  final AutomationModel rule;
  final bool isFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final VoidCallback onFavorite;

  const _AutomationCard({
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
    final scene = _AutomationsScreenState._sceneName(rule);
    final accent = _sceneColor(scene, rule.name);
    final statusText = _statusText(rule);
    final statusColor = _statusColor(rule);
    final extraMeta = _metaCount(rule) - 4;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _sceneIcon(scene, rule.name),
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rule.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _triggerSummary(rule),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        ..._metaIcons(rule, accent).take(4),
                        if (extraMeta > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              '+$extraMeta',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isUpdating)
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Switch(
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
              PopupMenuButton<String>(
                tooltip: 'Automation actions',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'view') {
                    onView();
                  }
                  if (value == 'edit') {
                    onEdit();
                  }
                  if (value == 'favorite') {
                    onFavorite();
                  }
                  if (value == 'delete') {
                    onDelete();
                  }
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

  static String _triggerSummary(AutomationModel rule) {
    if (rule.conditions.isEmpty) {
      return rule.description?.trim().isNotEmpty == true
          ? rule.description!.trim()
          : 'Manual automation';
    }
    final condition = rule.conditions.first;
    final time = condition.timeValue?.trim();
    if (time != null && time.isNotEmpty) {
      return '$time • Scheduled';
    }
    final property = condition.propertyName?.trim();
    if (property != null && property.isNotEmpty) {
      return '$property • Sensor trigger';
    }
    return 'Smart trigger';
  }

  static int _metaCount(AutomationModel rule) {
    final total = rule.conditions.length + rule.actions.length;
    return total == 0 ? 1 : total;
  }

  static Iterable<Widget> _metaIcons(AutomationModel rule, Color accent) sync* {
    final count = _metaCount(rule).clamp(1, 6).toInt();
    final iconPool = <IconData>[
      Icons.lightbulb_outline_rounded,
      Icons.blinds_rounded,
      Icons.sensors_rounded,
      Icons.security_rounded,
      Icons.power_rounded,
      Icons.schedule_rounded,
    ];
    for (var i = 0; i < count; i++) {
      yield Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Icon(iconPool[i % iconPool.length], color: accent, size: 14),
        ),
      );
    }
  }

  static String _statusText(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('alert') || name.contains('leak')) {
      return 'Alert';
    }
    return rule.isActive ? 'Active' : 'Paused';
  }

  static Color _statusColor(AutomationModel rule) {
    final name = rule.name.toLowerCase();
    if (name.contains('alert') || name.contains('leak')) {
      return AppColors.warning;
    }
    return rule.isActive ? AppColors.success : AppColors.textFaint;
  }

  static IconData _sceneIcon(String scene, String ruleName) {
    final name = ruleName.toLowerCase();
    if (name.contains('water') || name.contains('leak')) {
      return Icons.water_drop_rounded;
    }
    if (name.contains('energy')) {
      return Icons.bolt_rounded;
    }
    switch (scene) {
      case 'Morning':
        return Icons.wb_sunny_rounded;
      case 'Night':
        return Icons.nightlight_round;
      case 'Away':
        return Icons.shield_rounded;
      case 'Movie':
        return Icons.movie_rounded;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  static Color _sceneColor(String scene, String ruleName) {
    final name = ruleName.toLowerCase();
    if (name.contains('water') || name.contains('leak')) {
      return AppColors.warning;
    }
    if (name.contains('energy')) {
      return const Color(0xFF7C3AED);
    }
    switch (scene) {
      case 'Morning':
        return AppColors.primary;
      case 'Night':
        return const Color(0xFF3B82F6);
      case 'Away':
        return AppColors.primaryDark;
      case 'Movie':
        return const Color(0xFF6D28D9);
      default:
        return AppColors.primary;
    }
  }
}

class _SceneSuggestions extends StatelessWidget {
  final ValueChanged<_AutomationDraft> onApply;

  const _SceneSuggestions({required this.onApply});

  @override
  Widget build(BuildContext context) {
    const suggestions = <_SceneSuggestion>[
      _SceneSuggestion(
        title: 'Morning Energy',
        subtitle: 'Bright lights and fresh start',
        image: 'assets/images/scene_morning_ref.png',
        draft: _AutomationDraft(
          name: 'Morning Energy',
          trigger: '07:00',
          action: 'Turn on morning devices',
          repeat: 'Weekdays',
          scene: 'Morning',
        ),
      ),
      _SceneSuggestion(
        title: 'Movie Night',
        subtitle: 'Dim lights and perfect ambiance',
        image: 'assets/images/scene_movie_ref.png',
        draft: _AutomationDraft(
          name: 'Movie Night',
          trigger: '20:00',
          action: 'Dim lights and activate movie scene',
          repeat: 'Custom',
          scene: 'Custom',
        ),
      ),
      _SceneSuggestion(
        title: 'Away Mode',
        subtitle: 'Secure your home automatically',
        image: 'assets/images/scene_away_ref.png',
        draft: _AutomationDraft(
          name: 'Away Mode',
          trigger: '09:00',
          action: 'Turn off devices and secure the home',
          repeat: 'Custom',
          scene: 'Away',
        ),
      ),
      _SceneSuggestion(
        title: 'Sunset Calm',
        subtitle: 'Cozy lights and relaxing vibes',
        image: 'assets/images/scene_night_ref.png',
        draft: _AutomationDraft(
          name: 'Sunset Calm',
          trigger: '18:30',
          action: 'Set warm lights for the evening',
          repeat: 'Daily',
          scene: 'Night',
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Scene Suggestions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Spacer(),
            Text(
              'Swipe to explore',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _SceneSuggestionCard(
                suggestion: suggestion,
                onApply: () => onApply(suggestion.draft),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SceneSuggestionCard extends StatelessWidget {
  final _SceneSuggestion suggestion;
  final VoidCallback onApply;

  const _SceneSuggestionCard({required this.suggestion, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: Image.asset(suggestion.image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: OutlinedButton(
                    onPressed: onApply,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primarySoft,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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

class _AutomationHelpBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AutomationHelpBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6EFEB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/smart_robot.png',
              width: 66,
              height: 66,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
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
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "I'm here to help you set the perfect rules.",
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Ask Homez'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              side: const BorderSide(color: AppColors.primary),
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

class _EmptyAutomation extends StatelessWidget {
  final _AutomationFilter filter;
  final VoidCallback onAdd;

  const _EmptyAutomation({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final filtered = filter != _AutomationFilter.all;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'No matching automations' : 'No automations yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try another filter or create a new automation.'
                : 'Create a schedule, timer, or scene for your devices.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create automation'),
          ),
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
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _trigger =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  void _save() {
    if (!_key.currentState!.validate()) {
      return;
    }
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

class _SceneSuggestion {
  final String title;
  final String subtitle;
  final String image;
  final _AutomationDraft draft;

  const _SceneSuggestion({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.draft,
  });
}
