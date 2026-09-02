import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/severity_badge.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserName = auth.currentUser?.name ?? 'Operator';
    final activities = _filteredActivities(alertProvider.alerts);

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        leading: canPop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF0F172A),
                    size: 28,
                  ),
                  tooltip: 'Menu',
                  onPressed: () => openAppDrawer(ctx),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Stream',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'LIVE SYSTEM EVENT FEED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00A38E),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    // Gen-Z Hero Stream Status Card
                    _ActivityHero(alertProvider: alertProvider),
                    const SizedBox(height: 14),

                    // Search input
                    _ActivitySearchInput(
                      controller: _searchController,
                      onChanged: () => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Floating Category Filter Rail
                    _FilterRail(
                      selected: _filter,
                      onSelected: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (activities.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyActivityState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GenZActivityCard(
                        alert: activities[index],
                        userName: currentUserName,
                        onAcknowledge: () => alertProvider.acknowledge(
                          activities[index],
                          currentUserName,
                        ),
                        onResolve: () => alertProvider.resolve(
                          activities[index],
                          currentUserName,
                        ),
                        onTap: () => _showActivityDetailSheet(
                          context,
                          activities[index],
                          currentUserName,
                        ),
                      ),
                    ),
                    childCount: activities.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<AppAlert> _filteredActivities(List<AppAlert> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((alert) {
      final matchesFilter = switch (_filter) {
        _ActivityFilter.all => true,
        _ActivityFilter.newItems => !alert.acknowledged && !alert.resolved,
        _ActivityFilter.acknowledged => alert.acknowledged && !alert.resolved,
        _ActivityFilter.resolved => alert.resolved,
        _ActivityFilter.critical =>
          alert.severity == AlertSeverity.critical && !alert.resolved,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return alert.alertType.label.toLowerCase().contains(query) ||
          alert.location.toLowerCase().contains(query) ||
          alert.deviceId.toLowerCase().contains(query) ||
          alert.severity.label.toLowerCase().contains(query);
    }).toList();
  }

  void _showActivityDetailSheet(
    BuildContext context,
    AppAlert alert,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActivityDetailModal(alert: alert, userName: userName),
    );
  }
}

enum _ActivityFilter { all, newItems, acknowledged, resolved, critical }

class _ActivityHero extends StatelessWidget {
  final AlertProvider alertProvider;

  const _ActivityHero({required this.alertProvider});

  @override
  Widget build(BuildContext context) {
    final total = alertProvider.alerts.length;
    final resolved = alertProvider.alerts
        .where((activity) => activity.resolved)
        .length;
    final activeCritical = alertProvider.criticalActiveCount;
    final unacknowledged = alertProvider.alerts
        .where((a) => !a.acknowledged && !a.resolved)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2500A38E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stream_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'EVENT TIMELINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Live System Events',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeCritical > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.critical.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppColors.critical,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$activeCritical Critical',
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip(
                'Total Events',
                '$total',
                Icons.history_rounded,
                AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              _statChip(
                'Action Required',
                '$unacknowledged',
                Icons.priority_high_rounded,
                AppColors.warning,
              ),
              const SizedBox(width: 10),
              _statChip(
                'Resolved',
                '$resolved',
                Icons.task_alt_rounded,
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
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
}

class _ActivitySearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _ActivitySearchInput({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search event, location, device...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF00A38E),
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  final _ActivityFilter selected;
  final ValueChanged<_ActivityFilter> onSelected;

  const _FilterRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      {
        'f': _ActivityFilter.all,
        'label': 'All Feed',
        'icon': Icons.feed_rounded,
      },
      {
        'f': _ActivityFilter.newItems,
        'label': 'New Unread',
        'icon': Icons.fiber_new_rounded,
      },
      {
        'f': _ActivityFilter.acknowledged,
        'label': 'Acknowledged',
        'icon': Icons.visibility_rounded,
      },
      {
        'f': _ActivityFilter.resolved,
        'label': 'Resolved',
        'icon': Icons.check_circle_rounded,
      },
      {
        'f': _ActivityFilter.critical,
        'label': 'Critical Only',
        'icon': Icons.warning_rounded,
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((item) {
          final f = item['f'] as _ActivityFilter;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selected == f;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00A38E)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x2500A38E),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GenZActivityCard extends StatelessWidget {
  final AppAlert alert;
  final String userName;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onTap;

  const _GenZActivityCard({
    required this.alert,
    required this.userName,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = alert.resolved
        ? const Color(0xFF10B981)
        : alert.acknowledged
        ? const Color(0xFF0284C7)
        : alert.severity == AlertSeverity.critical
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);

    final statusText = alert.resolved
        ? 'RESOLVED'
        : alert.acknowledged
        ? 'ACKNOWLEDGED'
        : 'ACTION REQUIRED';

    final theme = _getTheme(alert);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.divider, width: 1.0),
        ),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon, Type Label, Severity Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: theme.gradient.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(theme.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.alertType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  alert.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SeverityBadge(severity: alert.severity),
                  ],
                ),
                const SizedBox(height: 12),

                // Device Chip and Telemetry
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.memory_rounded,
                        size: 14,
                        color: Color(0xFF00A38E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Device: ${alert.deviceId}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                      if (alert.value != null) ...[
                        const Spacer(),
                        Text(
                          'Metric: ${alert.value!.toStringAsFixed(1)}${alert.threshold != null ? ' / ${alert.threshold!.toStringAsFixed(0)}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00A38E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Footer: Timestamp, Status Pill, Quick Actions
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(alert.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Quick Action Bar if not resolved
                if (!alert.resolved) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!alert.acknowledged)
                        Expanded(
                          child: GestureDetector(
                            onTap: onAcknowledge,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0284C7,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0284C7,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 14,
                                    color: Color(0xFF0284C7),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Acknowledge',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!alert.acknowledged) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onResolve,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2500A38E),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Mark Resolved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(time);
  }

  _ActivityCardTheme _getTheme(AppAlert alert) {
    switch (alert.alertType) {
      case AlertType.smoke:
        return const _ActivityCardTheme(
          icon: Icons.local_fire_department_rounded,
          gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
        );
      case AlertType.gasLeak:
        return const _ActivityCardTheme(
          icon: Icons.propane_tank_rounded,
          gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
        );
      case AlertType.waterOverflow:
        return const _ActivityCardTheme(
          icon: Icons.waves_rounded,
          gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
        );
      case AlertType.pumpDryRun:
        return const _ActivityCardTheme(
          icon: Icons.water_damage_rounded,
          gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      case AlertType.highLoad:
        return const _ActivityCardTheme(
          icon: Icons.bolt_rounded,
          gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case AlertType.deviceOffline:
        return const _ActivityCardTheme(
          icon: Icons.cloud_off_rounded,
          gradient: [Color(0xFF64748B), Color(0xFF475569)],
        );
      case AlertType.general:
        return const _ActivityCardTheme(
          icon: Icons.info_rounded,
          gradient: [Color(0xFF00C9A7), Color(0xFF00A38E)],
        );
    }
  }
}

class _ActivityCardTheme {
  final IconData icon;
  final List<Color> gradient;

  const _ActivityCardTheme({required this.icon, required this.gradient});
}

class _ActivityDetailModal extends StatelessWidget {
  final AppAlert alert;
  final String userName;

  const _ActivityDetailModal({required this.alert, required this.userName});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.read<AlertProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A38E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: Color(0xFF00A38E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Incident #${alert.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SeverityBadge(severity: alert.severity),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.location_on_rounded, 'Location', alert.location),
          const SizedBox(height: 10),
          _detailRow(Icons.memory_rounded, 'Device ID', alert.deviceId),
          const SizedBox(height: 10),
          _detailRow(
            Icons.schedule_rounded,
            'Detected At',
            DateFormat('MMMM d, y • h:mm:ss a').format(alert.timestamp),
          ),
          if (alert.value != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.speed_rounded,
              'Telemetry Reading',
              '${alert.value!.toStringAsFixed(1)} (Threshold: ${alert.threshold?.toStringAsFixed(0) ?? 'N/A'})',
            ),
          ],
          if (alert.acknowledgedBy != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.visibility_rounded,
              'Acknowledged By',
              '${alert.acknowledgedBy} at ${DateFormat('h:mm a').format(alert.acknowledgedAt ?? DateTime.now())}',
            ),
          ],
          if (alert.resolvedBy != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.task_alt_rounded,
              'Resolved By',
              '${alert.resolvedBy} at ${DateFormat('h:mm a').format(alert.resolvedAt ?? DateTime.now())}',
            ),
          ],
          const SizedBox(height: 24),
          if (!alert.resolved)
            Row(
              children: [
                if (!alert.acknowledged)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        alertProvider.acknowledge(alert, userName);
                        Navigator.pop(context);
                      },
                      child: const Text('Acknowledge'),
                    ),
                  ),
                if (!alert.acknowledged) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A38E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      alertProvider.resolve(alert, userName);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark Resolved',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00A38E)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Activity Recorded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your smart ecosystem is running smoothly without alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
