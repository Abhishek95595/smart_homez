import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/automation_model.dart';
import '../../providers/automation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';
import '../../widgets/app_state_widgets.dart';
import 'automation_details_screen.dart';
import 'create_automation_screen.dart';

import '../scenes/scenes_screen.dart';

enum _AutomationFilter { all, active, disabled }

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  int _activeTab = 0; // 0: Automations, 1: Scenes
  _AutomationFilter _selectedFilter = _AutomationFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AutomationProvider>().fetchRules();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAutomation() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateAutomationScreen()));
  }

  Future<void> _editAutomation(AutomationModel rule) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateAutomationScreen(existingRule: rule),
      ),
    );
  }

  Future<void> _confirmDelete(AutomationModel rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete automation?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('“${rule.name}” will be permanently deleted.'),
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

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AutomationProvider>();
    final success = await provider.deleteRule(rule.id);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Automation deleted.' : 'Unable to delete automation.',
        ),
      ),
    );
  }

  void _showAutomationDetails(AutomationModel rule) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AutomationDetailsScreen(rule: rule)),
    );
  }

  static String _getTriggerTime(AutomationModel rule) {
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
    return '8:00 AM';
  }

  static String _formatTime12Hour(String timeStr) {
    if (timeStr.contains('AM') || timeStr.contains('PM')) return timeStr;
    final parts = timeStr.split(':');
    if (parts.isEmpty) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final isPm = hour >= 12;
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';
    return '$formattedHour:$formattedMinute $period';
  }

  static int _getDeviceCount(AutomationModel rule) {
    if (rule.actions.isNotEmpty) return rule.actions.length;
    final name = rule.name.toLowerCase();
    if (name.contains('movie')) return 4;
    if (name.contains('night')) return 3;
    if (name.contains('morning')) return 3;
    return 3;
  }

  static String _getActionSummary(AutomationModel rule) {
    if (rule.description != null && rule.description!.trim().isNotEmpty) {
      return rule.description!.trim();
    }
    if (rule.actions.isNotEmpty) {
      final summaries = rule.actions
          .map((a) => a.commandValue ?? a.command ?? 'Action')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (summaries.isNotEmpty) return summaries.join(', ');
    }
    final name = rule.name.toLowerCase();
    if (name.contains('morning')) {
      return 'Bedroom Light ON, Fan Speed 2, Living Room Light 70%';
    }
    if (name.contains('movie')) {
      return 'Living Room Light 20%, TV ON, Curtains Close';
    }
    if (name.contains('night')) {
      return 'All Lights OFF, Fan OFF, Door Lock ON';
    }
    return 'Run smart home routine commands';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationProvider>();

    // Filter rules
    final filteredRules = provider.rules.where((rule) {
      // 1. Status Filter
      if (_selectedFilter == _AutomationFilter.active && !rule.isActive) {
        return false;
      }
      if (_selectedFilter == _AutomationFilter.disabled && rule.isActive) {
        return false;
      }
      // 2. Search Query
      if (_searchQuery.isNotEmpty) {
        final matchesName = rule.name.toLowerCase().contains(_searchQuery);
        final matchesDesc =
            rule.description?.toLowerCase().contains(_searchQuery) ?? false;
        if (!matchesName && !matchesDesc) return false;
      }
      return true;
    }).toList();

    if (_activeTab == 1) {
      return const ScenesScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppNavigationDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          color: colorScheme.surface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => AppNavigationLeading.drawer(
                        color: colorScheme.onSurface,
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Automations',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Make your home work automatically ✨',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _activeTab = 1),
                    icon: Icon(
                      Icons.auto_awesome_rounded,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'View Scenes',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: provider.fetchRules,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
            children: [
              // 1. Search Bar with Filter Funnel Icon
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search Schedule ...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () => _searchController.clear(),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.filter_alt_outlined,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      onPressed: () => _showQuickFilterSheet(context),
                      tooltip: 'Filter options',
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Status Filter Pills Row (All, Active, Disabled)
              Row(
                children: [
                  _FilterPill(
                    label: 'All',
                    isSelected: _selectedFilter == _AutomationFilter.all,
                    onTap: () =>
                        setState(() => _selectedFilter = _AutomationFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _FilterPill(
                    label: 'Active',
                    isSelected: _selectedFilter == _AutomationFilter.active,
                    onTap: () => setState(
                      () => _selectedFilter = _AutomationFilter.active,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterPill(
                    label: 'Disabled',
                    isSelected: _selectedFilter == _AutomationFilter.disabled,
                    onTap: () => setState(
                      () => _selectedFilter = _AutomationFilter.disabled,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Primary Action Button: + Create Schedule
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2800897B),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _addAutomation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Create Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4. Automation Cards List
              if (provider.isLoading && provider.rules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingState(message: 'Loading automations…'),
                )
              else if (filteredRules.isEmpty)
                _EmptyAutomationsState(
                  hasFilter:
                      _selectedFilter != _AutomationFilter.all ||
                      _searchQuery.isNotEmpty,
                  onReset: () {
                    setState(() {
                      _selectedFilter = _AutomationFilter.all;
                      _searchController.clear();
                    });
                  },
                  onCreate: _addAutomation,
                )
              else
                ...filteredRules.map((rule) {
                  return _AutomationCard(
                    rule: rule,
                    triggerTime: _getTriggerTime(rule),
                    deviceCount: _getDeviceCount(rule),
                    actionSummary: _getActionSummary(rule),
                    onToggle: (val) {
                      provider.toggleRule(automationId: rule.id, isActive: val);
                    },
                    onEdit: () => _editAutomation(rule),
                    onDelete: () => _confirmDelete(rule),
                    onView: () => _showAutomationDetails(rule),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Filter Automations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.all_inclusive_rounded,
                color: Color(0xFF00897B),
              ),
              title: const Text(
                'Show All Automations',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                setState(() => _selectedFilter = _AutomationFilter.all);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF16A34A),
              ),
              title: const Text(
                'Show Active Only',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                setState(() => _selectedFilter = _AutomationFilter.active);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.pause_circle_outline_rounded,
                color: Color(0xFF64748B),
              ),
              title: const Text(
                'Show Disabled Only',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                setState(() => _selectedFilter = _AutomationFilter.disabled);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// FILTER PILL WIDGET
// ══════════════════════════════════════════════

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00897B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00897B)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1A00897B),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// AUTOMATION CARD WIDGET
// ══════════════════════════════════════════════

class _AutomationCard extends StatelessWidget {
  final AutomationModel rule;
  final String triggerTime;
  final int deviceCount;
  final String actionSummary;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _AutomationCard({
    required this.rule,
    required this.triggerTime,
    required this.deviceCount,
    required this.actionSummary,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getVisualTheme(rule.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Themed Icon Avatar Container
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: theme.iconWidget,
                ),

                const SizedBox(width: 14),

                // Middle & Right Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Title & Status Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rule.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.5,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: rule.isActive
                                  ? const Color(0xFFE8F8F5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rule.isActive ? 'Active' : 'Disabled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: rule.isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          // 3-Dots Menu
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (val) {
                              if (val == 'view') onView();
                              if (val == 'edit') onEdit();
                              if (val == 'delete') onDelete();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

                      const SizedBox(height: 4),

                      // Metadata & Toggle Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time / Trigger Row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Every day · $triggerTime',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                // Devices Count Row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.view_in_ar_rounded,
                                      size: 14.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$deviceCount devices',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Custom Sleek Switch
                          GestureDetector(
                            onTap: () => onToggle(!rule.isActive),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              width: 48,
                              height: 28,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: rule.isActive
                                    ? const Color(0xFF00897B)
                                    : const Color(0xFFCBD5E1),
                              ),
                              alignment: rule.isActive
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

                      const SizedBox(height: 8),

                      // Bottom Action Summary Row
                      Text(
                        actionSummary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static _VisualTheme _getVisualTheme(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('morning') ||
        lower.contains('sunrise') ||
        lower.contains('wakeup')) {
      return _VisualTheme(
        backgroundColor: const Color(0xFFFFF7ED),
        iconWidget: const Icon(
          Icons.wb_sunny_rounded,
          color: Color(0xFFF59E0B),
          size: 30,
        ),
      );
    }
    if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('tv') ||
        lower.contains('theatre')) {
      return _VisualTheme(
        backgroundColor: const Color(0xFFF3E8FF),
        iconWidget: const Icon(
          Icons.theaters_rounded,
          color: Color(0xFF7C3AED),
          size: 28,
        ),
      );
    }
    if (lower.contains('night') ||
        lower.contains('sleep') ||
        lower.contains('bedtime')) {
      return _VisualTheme(
        backgroundColor: const Color(0xFFE0E7FF),
        iconWidget: const Icon(
          Icons.nights_stay_rounded,
          color: Color(0xFF1E3A8A),
          size: 28,
        ),
      );
    }
    if (lower.contains('away') ||
        lower.contains('leave') ||
        lower.contains('out')) {
      return _VisualTheme(
        backgroundColor: const Color(0xFFF1F5F9),
        iconWidget: const Icon(
          Icons.directions_run_rounded,
          color: Color(0xFF475569),
          size: 28,
        ),
      );
    }
    if (lower.contains('party') ||
        lower.contains('celebrate') ||
        lower.contains('music')) {
      return _VisualTheme(
        backgroundColor: const Color(0xFFFCE7F3),
        iconWidget: const Icon(
          Icons.celebration_rounded,
          color: Color(0xFFDB2777),
          size: 28,
        ),
      );
    }
    return _VisualTheme(
      backgroundColor: const Color(0xFFE6F7F5),
      iconWidget: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF00897B),
        size: 28,
      ),
    );
  }
}

class _VisualTheme {
  final Color backgroundColor;
  final Widget iconWidget;

  const _VisualTheme({required this.backgroundColor, required this.iconWidget});
}

// ══════════════════════════════════════════════
// EMPTY STATE WIDGET
// ══════════════════════════════════════════════

class _EmptyAutomationsState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onReset;
  final VoidCallback onCreate;

  const _EmptyAutomationsState({
    required this.hasFilter,
    required this.onReset,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF00897B),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'No automations match your filter'
                : 'No automations yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try clearing your search query or selecting "All".'
                : 'Create routines to automatically manage your lights, climate, and security.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (hasFilter)
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Reset Filters'),
            )
          else
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Your First Automation'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
