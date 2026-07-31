import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../models/water_system.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_provider.dart';
import '../../theme/app_theme.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final waterProvider = context.watch<WaterProvider>();
    final role = context.watch<AuthProvider>().role;
    final canControl = role.canControlWaterPump;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Management'),
        bottom: canControl
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(32),
                child: _ViewOnlyBanner(),
              ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: waterProvider.tanks.length,
          itemBuilder: (context, i) =>
              _TankCard(tank: waterProvider.tanks[i], canControl: canControl),
        ),
      ),
    );
  }
}

class _ViewOnlyBanner extends StatelessWidget {
  const _ViewOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Center(
        child: Text(
          'View-only: pump control reserved for Admin/Manager/Maintenance',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TankCard extends StatelessWidget {
  final WaterTank tank;
  final bool canControl;
  const _TankCard({required this.tank, this.canControl = true});

  Color _stateColor() {
    switch (tank.pumpState) {
      case PumpState.running:
        return AppColors.success;
      case PumpState.stopped:
        return AppColors.textSecondary;
      case PumpState.dryRunFault:
        return AppColors.danger;
      case PumpState.maintenanceLockout:
        return AppColors.warning;
    }
  }

  String _stateLabel() {
    switch (tank.pumpState) {
      case PumpState.running:
        return 'Running';
      case PumpState.stopped:
        return 'Stopped';
      case PumpState.dryRunFault:
        return 'Dry-Run Fault';
      case PumpState.maintenanceLockout:
        return 'Maintenance Lockout';
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = tank.levelPercent <= tank.lowMark
        ? AppColors.danger
        : tank.levelPercent >= tank.highMark
        ? AppColors.warning
        : AppColors.primary;
    final runDuration = tank.displayedRunDuration;
    final runTime =
        '${runDuration.inHours}h ${runDuration.inMinutes.remainder(60)}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tank.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            tank.overflowProtectionEnabled
                ? 'Overflow prevention active'
                : 'Overflow prevention disabled',
            style: TextStyle(
              color: tank.overflowProtectionEnabled
                  ? AppColors.success
                  : AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (tank.pumpState == PumpState.dryRunFault) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.danger),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dry-run detected. Pump stopped for protection.',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 120,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 84,
                        height: (tank.levelPercent.clamp(0, 100) / 100) * 114,
                        child: Container(
                          color: levelColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Text(
                        '${tank.levelPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _stateColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _stateLabel(),
                          style: TextStyle(
                            color: _stateColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Low mark: ${tank.lowMark.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'High mark: ${tank.highMark.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (tank.dryRunEventCount > 0)
                      Text(
                        'Dry-run events: ${tank.dryRunEventCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WaterMetricCard(
                  icon: Icons.timer_outlined,
                  label: 'Running duration',
                  value: runTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WaterMetricCard(
                  icon: Icons.bolt_rounded,
                  label: 'Pump energy',
                  value: '${tank.energyUsageKwh.toStringAsFixed(2)} kWh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Mode:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              _modeChip(context, 'Auto', PumpMode.auto),
              const SizedBox(width: 8),
              _modeChip(context, 'Manual', PumpMode.manual),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canControl && tank.pumpMode == PumpMode.manual
                  ? () => context.read<WaterProvider>().togglePumpManual(tank)
                  : null,
              icon: Icon(
                tank.pumpState == PumpState.running
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_rounded,
              ),
              label: Text(
                tank.pumpState == PumpState.running
                    ? 'Stop Pump'
                    : 'Start Pump',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, String label, PumpMode mode) {
    final selected = tank.pumpMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: !canControl
          ? null
          : (_) => context.read<WaterProvider>().setPumpMode(tank, mode),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.divider),
    );
  }
}

class _WaterMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WaterMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
