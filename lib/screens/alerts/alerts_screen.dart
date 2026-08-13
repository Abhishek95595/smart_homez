import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/severity_badge.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertSeverity? _severityFilter;
  AlertType? _typeFilter;
  _AlertStatusFilter _statusFilter = _AlertStatusFilter.active;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final allAlerts = alertProvider.priorityAlerts;
    final alerts = _filteredAlerts(allAlerts);

    final activeCount = allAlerts.where((a) => !a.resolved).length;
    final ackCount =
        allAlerts.where((a) => a.acknowledged && !a.resolved).length;
    final resolvedCount = allAlerts.where((a) => a.resolved).length;

    final hasActiveFilters = _severityFilter != null ||
        _typeFilter != null ||
        _searchController.text.isNotEmpty ||
        _statusFilter != _AlertStatusFilter.active;

    final hasCritical = alertProvider.criticalActiveCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety & Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'REAL-TIME INCIDENT MONITOR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00A38E),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _severityFilter = null;
                    _typeFilter = null;
                    _statusFilter = _AlertStatusFilter.active;
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all_rounded,
                    size: 16, color: Color(0xFFEF4444)),
                label: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Emergency alert banner if critical incidents exist
                  if (hasCritical) ...[
                    _CriticalIncidentBanner(
                      count: alertProvider.criticalActiveCount,
                      onFilterCritical: () {
                        setState(() {
                          _severityFilter = AlertSeverity.critical;
                          _statusFilter = _AlertStatusFilter.active;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3 Hero Summary Stat Cards
                  _AlertSummaryRow(
                    alertProvider: alertProvider,
                    onSelectSeverity: (sev) {
                      setState(() {
                        if (_severityFilter == sev) {
                          _severityFilter = null;
                        } else {
                          _severityFilter = sev;
                          _statusFilter = _AlertStatusFilter.active;
                        }
                      });
                    },
                    onSelectAck: () {
                      setState(() {
                        _statusFilter = _AlertStatusFilter.acknowledged;
                        _severityFilter = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Search Box
                  _SearchBox(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // Animated Status Tabs with Count Badges
                  _StatusTabs(
                    selected: _statusFilter,
                    activeCount: activeCount,
                    ackCount: ackCount,
                    resolvedCount: resolvedCount,
                    totalCount: allAlerts.length,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 10),

                  // Filter Scroller
                  _FilterScroller(
                    severityFilter: _severityFilter,
                    typeFilter: _typeFilter,
                    onSeverityChanged: (value) =>
                        setState(() => _severityFilter = value),
                    onTypeChanged: (value) =>
                        setState(() => _typeFilter = value),
                    onClear: () => setState(() {
                      _severityFilter = null;
                      _typeFilter = null;
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: alerts.isEmpty
                  ? _EmptyAlertsState(
                      statusFilter: _statusFilter,
                      hasCustomFilters: hasActiveFilters,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      itemCount: alerts.length,
                      itemBuilder: (context, i) {
                        final alert = alerts[i];
                        final canAck = !alert.acknowledged &&
                            !alert.resolved &&
                            (user?.role.canAcknowledgeAlerts ?? false);
                        final canResolve = !alert.resolved &&
                            (user?.role.canAcknowledgeAlerts ?? false);
                        return _AlertCard(
                          alert: alert,
                          onTap: () => _showAlertDetails(context, alert, user),
                          onAcknowledge: canAck
                              ? () =>
                                  context.read<AlertProvider>().acknowledge(
                                        alert,
                                        user?.name ?? 'You',
                                      )
                              : null,
                          onResolve: canResolve
                              ? () => context.read<AlertProvider>().resolve(
                                    alert,
                                    user?.name ?? 'You',
                                  )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppAlert> _filteredAlerts(List<AppAlert> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((alert) {
      final statusOk = switch (_statusFilter) {
        _AlertStatusFilter.all => true,
        _AlertStatusFilter.active => !alert.resolved,
        _AlertStatusFilter.acknowledged =>
          alert.acknowledged && !alert.resolved,
        _AlertStatusFilter.resolved => alert.resolved,
      };
      if (!statusOk) return false;
      if (_severityFilter != null && alert.severity != _severityFilter) {
        return false;
      }
      if (_typeFilter != null && alert.alertType != _typeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return alert.alertType.label.toLowerCase().contains(query) ||
          alert.location.toLowerCase().contains(query) ||
          alert.deviceId.toLowerCase().contains(query) ||
          alert.severity.label.toLowerCase().contains(query);
    }).toList();
  }

  void _showAlertDetails(
      BuildContext context, AppAlert alert, AppUser? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertDetailsSheet(
        alert: alert,
        canAck: !alert.acknowledged &&
            !alert.resolved &&
            (user?.role.canAcknowledgeAlerts ?? false),
        canResolve:
            !alert.resolved && (user?.role.canAcknowledgeAlerts ?? false),
        onAcknowledge: () {
          context
              .read<AlertProvider>()
              .acknowledge(alert, user?.name ?? 'You');
          Navigator.pop(context);
        },
        onResolve: () {
          context.read<AlertProvider>().resolve(alert, user?.name ?? 'You');
          Navigator.pop(context);
        },
      ),
    );
  }
}

enum _AlertStatusFilter { active, acknowledged, resolved, all }

class _CriticalIncidentBanner extends StatelessWidget {
  final int count;
  final VoidCallback onFilterCritical;

  const _CriticalIncidentBanner({
    required this.count,
    required this.onFilterCritical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35EF4444),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Critical Safety Incident${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Immediate attention required for active property safety',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onFilterCritical,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            child: const Text('VIEW'),
          ),
        ],
      ),
    );
  }
}

class _AlertSummaryRow extends StatelessWidget {
  final AlertProvider alertProvider;
  final ValueChanged<AlertSeverity> onSelectSeverity;
  final VoidCallback onSelectAck;

  const _AlertSummaryRow({
    required this.alertProvider,
    required this.onSelectSeverity,
    required this.onSelectAck,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryTile(
          label: 'Critical',
          value: alertProvider.criticalActiveCount,
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          icon: Icons.shield_outlined,
          onTap: () => onSelectSeverity(AlertSeverity.critical),
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'High Priority',
          value: alertProvider.activeHighCount,
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFFBEB),
          icon: Icons.warning_amber_rounded,
          onTap: () => onSelectSeverity(AlertSeverity.high),
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'Acknowledged',
          value: alertProvider.acknowledgedCount,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
          icon: Icons.task_alt_rounded,
          onTap: onSelectAck,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search alert, device, or location...',
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
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final _AlertStatusFilter selected;
  final int activeCount;
  final int ackCount;
  final int resolvedCount;
  final int totalCount;
  final ValueChanged<_AlertStatusFilter> onChanged;

  const _StatusTabs({
    required this.selected,
    required this.activeCount,
    required this.ackCount,
    required this.resolvedCount,
    required this.totalCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {
        'filter': _AlertStatusFilter.active,
        'label': 'Active',
        'count': activeCount
      },
      {'filter': _AlertStatusFilter.acknowledged, 'label': 'Ack.', 'count': ackCount},
      {
        'filter': _AlertStatusFilter.resolved,
        'label': 'Resolved',
        'count': resolvedCount
      },
      {'filter': _AlertStatusFilter.all, 'label': 'All', 'count': totalCount},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.map((t) {
          final filter = t['filter'] as _AlertStatusFilter;
          final label = t['label'] as String;
          final count = t['count'] as int;
          final isSelected = selected == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
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

class _FilterScroller extends StatelessWidget {
  final AlertSeverity? severityFilter;
  final AlertType? typeFilter;
  final ValueChanged<AlertSeverity?> onSeverityChanged;
  final ValueChanged<AlertType?> onTypeChanged;
  final VoidCallback onClear;

  const _FilterScroller({
    required this.severityFilter,
    required this.typeFilter,
    required this.onSeverityChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = severityFilter != null || typeFilter != null;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 13, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _chip(
            label: 'Critical',
            selected: severityFilter == AlertSeverity.critical,
            color: const Color(0xFFEF4444),
            onTap: () => onSeverityChanged(
                severityFilter == AlertSeverity.critical
                    ? null
                    : AlertSeverity.critical),
          ),
          _chip(
            label: 'High',
            selected: severityFilter == AlertSeverity.high,
            color: const Color(0xFFF59E0B),
            onTap: () => onSeverityChanged(severityFilter == AlertSeverity.high
                ? null
                : AlertSeverity.high),
          ),
          _chip(
            label: 'Medium',
            selected: severityFilter == AlertSeverity.medium,
            color: const Color(0xFF3B82F6),
            onTap: () => onSeverityChanged(
                severityFilter == AlertSeverity.medium
                    ? null
                    : AlertSeverity.medium),
          ),
          _chip(
            label: 'Low',
            selected: severityFilter == AlertSeverity.low,
            color: const Color(0xFF10B981),
            onTap: () => onSeverityChanged(severityFilter == AlertSeverity.low
                ? null
                : AlertSeverity.low),
          ),
          _chip(
            label: 'Smoke',
            selected: typeFilter == AlertType.smoke,
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFEA580C),
            onTap: () => onTypeChanged(
                typeFilter == AlertType.smoke ? null : AlertType.smoke),
          ),
          _chip(
            label: 'Gas Leak',
            selected: typeFilter == AlertType.gasLeak,
            icon: Icons.gas_meter_rounded,
            color: const Color(0xFFDC2626),
            onTap: () => onTypeChanged(
                typeFilter == AlertType.gasLeak ? null : AlertType.gasLeak),
          ),
          _chip(
            label: 'Water Overflow',
            selected: typeFilter == AlertType.waterOverflow,
            icon: Icons.water_damage_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => onTypeChanged(typeFilter == AlertType.waterOverflow
                ? null
                : AlertType.waterOverflow),
          ),
          _chip(
            label: 'Offline',
            selected: typeFilter == AlertType.deviceOffline,
            icon: Icons.wifi_off_rounded,
            color: const Color(0xFF64748B),
            onTap: () => onTypeChanged(typeFilter == AlertType.deviceOffline
                ? null
                : AlertType.deviceOffline),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : const Color(0xFFCBD5E1),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(width: 4),
              ] else ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  const _AlertCard({
    required this.alert,
    required this.onTap,
    this.onAcknowledge,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = AppTheme.severityColor(alert.severity.label);
    final df = DateFormat('MMM d, h:mm a');

    final bool isResolved = alert.resolved;
    final bool isAck = alert.acknowledged && !isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isResolved
              ? const Color(0xFFE2E8F0)
              : sevColor.withValues(alpha: 0.45),
          width: isResolved ? 1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isResolved
                ? const Color(0x04000000)
                : sevColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Left Severity Accent Indicator Bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5.5,
                  child: Container(
                    color: isResolved ? const Color(0xFFCBD5E1) : sevColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFFF1F5F9)
                                  : sevColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              _iconFor(alert.alertType),
                              color: isResolved
                                  ? const Color(0xFF64748B)
                                  : sevColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SeverityBadge(severity: alert.severity),
                                    const SizedBox(width: 8),
                                    if (isResolved)
                                      const _StatusPill(
                                        label: 'RESOLVED',
                                        color: Color(0xFF10B981),
                                        icon: Icons.check_circle_rounded,
                                      )
                                    else if (isAck)
                                      const _StatusPill(
                                        label: 'ACKNOWLEDGED',
                                        color: Color(0xFFF59E0B),
                                        icon: Icons.pending_actions_rounded,
                                      )
                                    else
                                      const _StatusPill(
                                        label: 'LIVE ACTIVE',
                                        color: Color(0xFFEF4444),
                                        icon: Icons.radio_button_checked_rounded,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert.alertType.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    color: isResolved
                                        ? const Color(0xFF475569)
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Metadata Badges (Location, Device, Time)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.location_on_rounded,
                            text: alert.location,
                            iconColor: const Color(0xFF00A38E),
                          ),
                          _MetaChip(
                            icon: Icons.memory_rounded,
                            text: alert.deviceId,
                            iconColor: const Color(0xFF3B82F6),
                          ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            text: df.format(alert.timestamp),
                            iconColor: const Color(0xFF64748B),
                          ),
                        ],
                      ),

                      // Threshold Gauge if applicable
                      if (alert.value != null && alert.threshold != null) ...[
                        const SizedBox(height: 14),
                        _ThresholdGauge(
                          value: alert.value!,
                          threshold: alert.threshold!,
                          isResolved: isResolved,
                        ),
                      ],

                      // Audit Log
                      if (alert.acknowledged && alert.acknowledgedBy != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_pin_rounded,
                                  size: 14, color: Color(0xFF00A38E)),
                              const SizedBox(width: 6),
                              Text(
                                'Acknowledged by ${alert.acknowledgedBy}${alert.acknowledgedAt == null ? '' : ' • ${df.format(alert.acknowledgedAt!)}'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (alert.resolved && alert.resolvedBy != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                'Resolved by ${alert.resolvedBy}${alert.resolvedAt == null ? '' : ' • ${df.format(alert.resolvedAt!)}'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons
                      if (onAcknowledge != null || onResolve != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (onAcknowledge != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onAcknowledge,
                                  icon:
                                      const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Acknowledge'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                        color: Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            if (onAcknowledge != null && onResolve != null)
                              const SizedBox(width: 10),
                            if (onResolve != null)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C9A7),
                                        Color(0xFF00A38E)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x2500A38E),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: onResolve,
                                    icon: const Icon(
                                      Icons.task_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text('Mark Resolved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AlertType type) {
    return switch (type) {
      AlertType.smoke => Icons.local_fire_department_rounded,
      AlertType.gasLeak => Icons.gas_meter_rounded,
      AlertType.waterOverflow => Icons.water_damage_rounded,
      AlertType.pumpDryRun => Icons.water_drop_outlined,
      AlertType.highLoad => Icons.bolt_rounded,
      AlertType.deviceOffline => Icons.wifi_off_rounded,
      AlertType.general => Icons.info_rounded,
    };
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdGauge extends StatelessWidget {
  final double value;
  final double threshold;
  final bool isResolved;

  const _ThresholdGauge({
    required this.value,
    required this.threshold,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = threshold <= 0
        ? 1.0
        : (value / threshold).clamp(0.0, 1.4).toDouble();
    final isOver = value >= threshold && !isResolved;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOver ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOver ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading: ${value.toStringAsFixed(1)} (Limit: ${threshold.toStringAsFixed(1)})',
                style: TextStyle(
                  color: isOver
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isOver
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOver ? 'EXCEEDED' : 'NORMAL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? const Color(0xFFEF4444) : const Color(0xFF00A38E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  final _AlertStatusFilter statusFilter;
  final bool hasCustomFilters;

  const _EmptyAlertsState({
    required this.statusFilter,
    required this.hasCustomFilters,
  });

  @override
  Widget build(BuildContext context) {
    final title = hasCustomFilters
        ? 'No matching alerts found'
        : 'All Systems Normal & Safe';

    final message = hasCustomFilters
        ? 'Try clearing or adjusting your active filter selections.'
        : switch (statusFilter) {
            _AlertStatusFilter.active =>
              'No active safety or hardware issues detected in any of your monitored properties.',
            _AlertStatusFilter.acknowledged =>
              'No pending acknowledged alerts found at the moment.',
            _AlertStatusFilter.resolved =>
              'No resolved alerts recorded in this filter period.',
            _AlertStatusFilter.all => 'No alerts recorded in the system.',
          };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F8F5), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1500A38E),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF00A38E),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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

class _AlertDetailsSheet extends StatelessWidget {
  final AppAlert alert;
  final bool canAck;
  final bool canResolve;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const _AlertDetailsSheet({
    required this.alert,
    required this.canAck,
    required this.canResolve,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = AppTheme.severityColor(alert.severity.label);
    final df = DateFormat('MMMM d, yyyy • hh:mm a');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.security_rounded, color: sevColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityBadge(severity: alert.severity),
                        const SizedBox(width: 8),
                        Text(
                          alert.resolved
                              ? 'RESOLVED'
                              : (alert.acknowledged
                                  ? 'ACKNOWLEDGED'
                                  : 'ACTIVE'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: alert.resolved
                                ? const Color(0xFF10B981)
                                : (alert.acknowledged
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.alertType.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Incident details
          _sheetRow(Icons.location_on_rounded, 'Location', alert.location),
          _sheetRow(Icons.memory_rounded, 'Device ID', alert.deviceId),
          _sheetRow(Icons.schedule_rounded, 'Triggered',
              df.format(alert.timestamp)),

          if (alert.value != null && alert.threshold != null)
            _sheetRow(
              Icons.speed_rounded,
              'Telemetry Reading',
              '${alert.value!.toStringAsFixed(1)} (Threshold limit: ${alert.threshold!.toStringAsFixed(1)})',
            ),

          if (alert.acknowledgedBy != null)
            _sheetRow(
              Icons.person_pin_rounded,
              'Acknowledged By',
              '${alert.acknowledgedBy!} ${alert.acknowledgedAt == null ? '' : '(${df.format(alert.acknowledgedAt!)})'}',
            ),

          if (alert.resolvedBy != null)
            _sheetRow(
              Icons.verified_rounded,
              'Resolved By',
              '${alert.resolvedBy!} ${alert.resolvedAt == null ? '' : '(${df.format(alert.resolvedAt!)})'}',
            ),

          const SizedBox(height: 20),

          // Action buttons in sheet
          if (canAck || canResolve)
            Row(
              children: [
                if (canAck)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAcknowledge,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Acknowledge Alert',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                if (canAck && canResolve) const SizedBox(width: 12),
                if (canResolve)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A38E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Mark as Resolved',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sheetRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
