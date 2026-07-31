import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
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
    final alerts = _filteredAlerts(alertProvider.priorityAlerts);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _AlertSummaryRow(alertProvider: alertProvider),
                  const SizedBox(height: 14),
                  _SearchBox(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _StatusTabs(
                    selected: _statusFilter,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 10),
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
                  ? _EmptyAlertsState(statusFilter: _statusFilter)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        return _AlertCard(
                          alert: alert,
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
}

enum _AlertStatusFilter { active, acknowledged, resolved, all }

class _AlertSummaryRow extends StatelessWidget {
  final AlertProvider alertProvider;
  const _AlertSummaryRow({required this.alertProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryTile(
          label: 'Critical',
          value: alertProvider.criticalActiveCount,
          color: AppColors.critical,
          icon: Icons.priority_high_rounded,
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'High',
          value: alertProvider.activeHighCount,
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(width: 10),
        _SummaryTile(
          label: 'Ack',
          value: alertProvider.acknowledgedCount,
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
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
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search alert, location, device...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final _AlertStatusFilter selected;
  final ValueChanged<_AlertStatusFilter> onChanged;

  const _StatusTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('Active', _AlertStatusFilter.active),
        const SizedBox(width: 8),
        _tab('Ack.', _AlertStatusFilter.acknowledged),
        const SizedBox(width: 8),
        _tab('Resolved', _AlertStatusFilter.resolved),
        const SizedBox(width: 8),
        _tab('All', _AlertStatusFilter.all),
      ],
    );
  }

  Widget _tab(String label, _AlertStatusFilter value) {
    final isSelected = selected == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (hasFilter) _actionChip('Clear', onClear),
          _severityChip('Critical', AlertSeverity.critical),
          _severityChip('High', AlertSeverity.high),
          _severityChip('Medium', AlertSeverity.medium),
          _severityChip('Low', AlertSeverity.low),
          _typeChip('Smoke', AlertType.smoke),
          _typeChip('Gas', AlertType.gasLeak),
          _typeChip('Water', AlertType.waterOverflow),
          _typeChip('Offline', AlertType.deviceOffline),
        ],
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _severityChip(String label, AlertSeverity value) {
    final selected = severityFilter == value;
    return _choiceChip(
      label: label,
      selected: selected,
      onSelected: (_) => onSeverityChanged(selected ? null : value),
    );
  }

  Widget _typeChip(String label, AlertType value) {
    final selected = typeFilter == value;
    return _choiceChip(
      label: label,
      selected: selected,
      onSelected: (_) => onTypeChanged(selected ? null : value),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.divider),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  const _AlertCard({required this.alert, this.onAcknowledge, this.onResolve});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(alert.severity.label);
    final df = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.resolved
              ? AppColors.divider
              : color.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_iconFor(alert.alertType), color: color),
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
                        if (alert.resolved)
                          const _StatusPill(
                            label: 'Resolved',
                            color: AppColors.success,
                          )
                        else if (!alert.acknowledged)
                          const _StatusPill(
                            label: 'Active',
                            color: AppColors.warning,
                          )
                        else
                          const _StatusPill(
                            label: 'Acknowledged',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      alert.alertType.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(icon: Icons.location_on_rounded, text: alert.location),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.memory_rounded,
            text: 'Device: ${alert.deviceId}',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.schedule_rounded,
            text: df.format(alert.timestamp),
          ),
          if (alert.value != null && alert.threshold != null) ...[
            const SizedBox(height: 10),
            _ValueBar(value: alert.value!, threshold: alert.threshold!),
          ],
          if (alert.acknowledged && alert.acknowledgedBy != null) ...[
            const SizedBox(height: 10),
            Text(
              'Acknowledged by ${alert.acknowledgedBy}'
              '${alert.acknowledgedAt == null ? '' : ' • ${df.format(alert.acknowledgedAt!)}'}',
              style: const TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ],
          if (alert.resolved && alert.resolvedBy != null) ...[
            const SizedBox(height: 6),
            Text(
              'Resolved by ${alert.resolvedBy}'
              '${alert.resolvedAt == null ? '' : ' • ${df.format(alert.resolvedAt!)}'}',
              style: const TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ],
          if (onAcknowledge != null || onResolve != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onAcknowledge != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAcknowledge,
                      child: const Text('Acknowledge'),
                    ),
                  ),
                if (onAcknowledge != null && onResolve != null)
                  const SizedBox(width: 8),
                if (onResolve != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onResolve,
                      child: const Text('Mark Resolved'),
                    ),
                  ),
              ],
            ),
          ],
        ],
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueBar extends StatelessWidget {
  final double value;
  final double threshold;

  const _ValueBar({required this.value, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final ratio = threshold <= 0
        ? 1.0
        : (value / threshold).clamp(0.0, 1.4).toDouble();
    final isOver = value >= threshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Value ${value.toStringAsFixed(1)} / threshold ${threshold.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              isOver ? 'Over limit' : 'Within limit',
              style: TextStyle(
                color: isOver ? AppColors.critical : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOver ? AppColors.critical : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  final _AlertStatusFilter statusFilter;
  const _EmptyAlertsState({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final message = switch (statusFilter) {
      _AlertStatusFilter.active => 'No active alerts right now.',
      _AlertStatusFilter.acknowledged => 'No acknowledged alerts found.',
      _AlertStatusFilter.resolved => 'No resolved alerts found.',
      _AlertStatusFilter.all => 'No alerts match your filters.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
