import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import 'alerts_theme.dart';
import 'widgets/alert_details_sheet.dart';
import 'widgets/alert_filter_scroller.dart';
import 'widgets/alert_search_bar.dart';
import 'widgets/alert_status_tabs.dart';
import 'widgets/alerts_empty_state.dart';
import 'widgets/safety_alert_card.dart';
import 'widgets/safety_hero_card.dart';
import 'widgets/safety_summary_row.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertSeverity? _severityFilter;
  AlertType? _typeFilter;
  AlertStatusFilter _statusFilter = AlertStatusFilter.active;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlertsTheme.of(context);
    final alertProvider = context.watch<AlertProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final allAlerts = alertProvider.priorityAlerts;
    final alerts = _filteredAlerts(allAlerts);

    final activeCount = allAlerts.where((a) => !a.resolved).length;
    final ackCount = allAlerts
        .where((a) => a.acknowledged && !a.resolved)
        .length;
    final resolvedCount = allAlerts.where((a) => a.resolved).length;

    final hasActiveFilters =
        _severityFilter != null ||
        _typeFilter != null ||
        _searchController.text.isNotEmpty ||
        _statusFilter != AlertStatusFilter.active;

    final hasCritical = alertProvider.criticalActiveCount > 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.panel,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? BackButton(color: colors.textPrimary)
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety & Alerts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'REAL-TIME INCIDENT MONITOR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.accent,
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
                    _statusFilter = AlertStatusFilter.active;
                    _searchController.clear();
                  });
                },
                icon: Icon(
                  Icons.clear_all_rounded,
                  size: 16,
                  color: colors.criticalText,
                ),
                label: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.criticalText,
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
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border(bottom: BorderSide(color: colors.border)),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Emergency alert banner if critical incidents exist
                  if (hasCritical) ...[
                    SafetyHeroCard(
                      count: alertProvider.criticalActiveCount,
                      onFilterCritical: () {
                        setState(() {
                          _severityFilter = AlertSeverity.critical;
                          _statusFilter = AlertStatusFilter.active;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3 Summary Cards Row (Critical, High Priority, Acknowledged)
                  SafetySummaryRow(
                    alertProvider: alertProvider,
                    onSelectSeverity: (sev) {
                      setState(() {
                        if (_severityFilter == sev) {
                          _severityFilter = null;
                        } else {
                          _severityFilter = sev;
                          _statusFilter = AlertStatusFilter.active;
                        }
                      });
                    },
                    onSelectAck: () {
                      setState(() {
                        _statusFilter = AlertStatusFilter.acknowledged;
                        _severityFilter = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Search Box
                  AlertSearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // Segmented Status Control Tabs
                  AlertStatusTabs(
                    selected: _statusFilter,
                    activeCount: activeCount,
                    ackCount: ackCount,
                    resolvedCount: resolvedCount,
                    totalCount: allAlerts.length,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 10),

                  // Severity & Type Filter Scroller
                  AlertFilterScroller(
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
                  ? AlertsEmptyState(
                      statusFilter: _statusFilter,
                      hasCustomFilters: hasActiveFilters,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      itemCount: alerts.length,
                      itemBuilder: (context, i) {
                        final alert = alerts[i];
                        final canAck =
                            !alert.acknowledged &&
                            !alert.resolved &&
                            (user?.role.canAcknowledgeAlerts ?? false);
                        final canResolve =
                            !alert.resolved &&
                            (user?.role.canAcknowledgeAlerts ?? false);
                        return SafetyAlertCard(
                          alert: alert,
                          onTap: () => _showAlertDetails(context, alert, user),
                          onAcknowledge: canAck
                              ? () => context.read<AlertProvider>().acknowledge(
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
        AlertStatusFilter.all => true,
        AlertStatusFilter.active => !alert.resolved,
        AlertStatusFilter.acknowledged => alert.acknowledged && !alert.resolved,
        AlertStatusFilter.resolved => alert.resolved,
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

  void _showAlertDetails(BuildContext context, AppAlert alert, AppUser? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlertDetailsSheet(
        alert: alert,
        canAck:
            !alert.acknowledged &&
            !alert.resolved &&
            (user?.role.canAcknowledgeAlerts ?? false),
        canResolve:
            !alert.resolved && (user?.role.canAcknowledgeAlerts ?? false),
        onAcknowledge: () {
          context.read<AlertProvider>().acknowledge(alert, user?.name ?? 'You');
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
