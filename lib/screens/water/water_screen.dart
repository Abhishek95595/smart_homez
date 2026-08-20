import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/user_role.dart';
import '../../models/water_system.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _selectedTankIndex = 0;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final waterProvider = context.watch<WaterProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final role = context.watch<AuthProvider>().role;
    final canControl = role.canControlWaterPump;
    final tanks = waterProvider.tanks;

    if (tanks.isNotEmpty && _selectedTankIndex >= tanks.length) {
      _selectedTankIndex = 0;
    }

    final selectedTank = tanks.isEmpty ? null : tanks[_selectedTankIndex];
    final activeOverflowAlerts = alertProvider.activeAlerts
        .where((alert) => alert.alertType == AlertType.waterOverflow)
        .length;
    final totalOverflowEvents = tanks.fold<int>(
      0,
      (sum, tank) => sum + tank.overflowEventCount,
    );
    final activeLeaks = activeOverflowAlerts + totalOverflowEvents;
    final runningPumps = tanks
        .where((tank) => tank.pumpState == PumpState.running)
        .length;
    final averageLevel = tanks.isEmpty
        ? 0.0
        : tanks.fold<double>(0, (sum, tank) => sum + tank.levelPercent) /
              tanks.length;
    final allNormal =
        activeLeaks == 0 &&
        tanks.every(
          (tank) =>
              tank.pumpState != PumpState.dryRunFault &&
              tank.pumpState != PumpState.maintenanceLockout,
        );

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WaterHeader(
              alertCount: alertProvider.activeAlerts.length,
              onAlerts: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                children: [
                  _WaterHero(
                    allNormal: allNormal,
                    activeLeaks: activeLeaks,
                    mainTankLevel: averageLevel,
                    pumpRunning: runningPumps > 0,
                  ),
                  const SizedBox(height: 18),
                  _WaterTabs(
                    selectedIndex: _selectedTab,
                    onChanged: (index) => setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: 18),
                  if (!canControl) ...[
                    const _ViewOnlyBanner(),
                    const SizedBox(height: 14),
                  ],
                  if (tanks.isEmpty)
                    const _EmptyWaterState()
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 720) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TankLevelsCard(
                                  tanks: tanks,
                                  selectedIndex: _selectedTankIndex,
                                  onSelect: (index) => setState(
                                    () => _selectedTankIndex = index,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _PumpStatusCard(
                                  tank: selectedTank!,
                                  canControl: canControl,
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _TankLevelsCard(
                              tanks: tanks,
                              selectedIndex: _selectedTankIndex,
                              onSelect: (index) =>
                                  setState(() => _selectedTankIndex = index),
                            ),
                            const SizedBox(height: 14),
                            _PumpStatusCard(
                              tank: selectedTank!,
                              canControl: canControl,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _LeakStatusBanner(
                      leakCount: activeLeaks,
                      onReview: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 720) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _UsageCard(tanks: tanks)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _QuickActionsCard(
                                  overflowAlerts: activeOverflowAlerts,
                                  onAlerts: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AlertsScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _UsageCard(tanks: tanks),
                            const SizedBox(height: 14),
                            _QuickActionsCard(
                              overflowAlerts: activeOverflowAlerts,
                              onAlerts: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AlertsScreen(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _WaterAssistantStrip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback onAlerts;

  const _WaterHeader({required this.alertCount, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, size: 28),
            ),
          ),
          Expanded(
            child: Column(
              children: const [
                Text(
                  'Water Management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Monitor usage, tanks and prevent overflow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onAlerts,
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
              ),
              if (alertCount > 0)
                Positioned(
                  right: 4,
                  top: 3,
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

class _WaterHero extends StatelessWidget {
  final bool allNormal;
  final int activeLeaks;
  final double mainTankLevel;
  final bool pumpRunning;

  const _WaterHero({
    required this.allNormal,
    required this.activeLeaks,
    required this.mainTankLevel,
    required this.pumpRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF9F7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD8F0EC)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            width: 140,
            height: 135,
            child: Image.asset(
              'assets/images/water_robot_ref.png',
              fit: BoxFit.contain,
              alignment: Alignment.topRight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allNormal ? 'All Systems' : 'Water System',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      allNormal ? 'Normal' : 'Needs Attention',
                      style: TextStyle(
                        color: allNormal
                            ? AppColors.primaryDark
                            : AppColors.danger,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      allNormal
                          ? Icons.verified_user_outlined
                          : Icons.warning_amber_rounded,
                      color: allNormal ? AppColors.primary : AppColors.danger,
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 170,
                  child: Text(
                    allNormal
                        ? 'Your water systems are working perfectly.\nNo leaks detected.'
                        : '$activeLeaks water alert${activeLeaks == 1 ? '' : 's'} need review.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      _HeroWaterMetric(
                        icon: Icons.water_drop_outlined,
                        value: '$activeLeaks',
                        label: 'Active Leaks',
                        color: activeLeaks == 0
                            ? AppColors.primary
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      _HeroWaterMetric(
                        icon: Icons.water_outlined,
                        value: '${mainTankLevel.round()}%',
                        label: 'Avg. Tank',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      _HeroWaterMetric(
                        icon: Icons.settings_input_component_rounded,
                        value: pumpRunning ? 'ON' : 'OFF',
                        label: 'Pump Status',
                        color: pumpRunning
                            ? AppColors.success
                            : AppColors.textSecondary,
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

class _HeroWaterMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroWaterMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _WaterTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Overview',
      'Tanks',
      'Pumps',
      'Usage',
      'History',
      'Settings',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = selectedIndex == index;
            return InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'View only: pump control is reserved for Admin, Manager or Maintenance roles.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TankLevelsCard extends StatelessWidget {
  final List<WaterTank> tanks;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TankLevelsCard({
    required this.tanks,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selected = tanks[selectedIndex];
    return _WhiteSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Water Tank Levels'),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.84,
                    child: Image.asset(
                      'assets/images/water_tank_ref.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.levelPercent.round()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Low ${selected.lowMark.round()}% • High ${selected.highMark.round()}%',
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
          const SizedBox(height: 8),
          for (int i = 0; i < tanks.length; i++) ...[
            _TankLevelRow(
              tank: tanks[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
            if (i != tanks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TankLevelRow extends StatelessWidget {
  final WaterTank tank;
  final bool selected;
  final VoidCallback onTap;

  const _TankLevelRow({
    required this.tank,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : const Color(0xFFFBFCFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: (tank.levelPercent / 100)
                    .clamp(0.08, 1.0)
                    .toDouble(),
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tank.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${tank.levelPercent.round()}%',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: (tank.levelPercent / 100)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      backgroundColor: const Color(0xFFEAF0F1),
                      color: tank.levelPercent <= tank.lowMark
                          ? AppColors.danger
                          : AppColors.primary,
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

class _PumpStatusCard extends StatelessWidget {
  final WaterTank tank;
  final bool canControl;

  const _PumpStatusCard({required this.tank, required this.canControl});

  @override
  Widget build(BuildContext context) {
    final running = tank.pumpState == PumpState.running;
    final duration = tank.displayedRunDuration;
    final runTime = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';

    return _WhiteSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Water Pump Status'),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 110,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.84,
                    child: Image.asset(
                      'assets/images/water_pump_ref.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Main Pump',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _StatusPill(
                          text: running ? 'ON' : 'OFF',
                          active: running,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _PumpInfoRow(
                      label: 'Mode',
                      value: tank.pumpMode.name == 'auto' ? 'Auto' : 'Manual',
                    ),
                    _PumpInfoRow(label: 'Runtime', value: runTime),
                    _PumpInfoRow(
                      label: 'Energy',
                      value: '${tank.energyUsageKwh.toStringAsFixed(2)} kWh',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Pump Controls',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      canControl && tank.pumpMode == PumpMode.manual && !running
                      ? () =>
                            context.read<WaterProvider>().togglePumpManual(tank)
                      : null,
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text('Pump ON'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      canControl && tank.pumpMode == PumpMode.manual && running
                      ? () =>
                            context.read<WaterProvider>().togglePumpManual(tank)
                      : null,
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text('Pump OFF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFF2B9BD)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: 'Auto',
                    selected: tank.pumpMode == PumpMode.auto,
                    enabled: canControl,
                    onTap: () => context.read<WaterProvider>().setPumpMode(
                      tank,
                      PumpMode.auto,
                    ),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: 'Manual',
                    selected: tank.pumpMode == PumpMode.manual,
                    enabled: canControl,
                    onTap: () => context.read<WaterProvider>().setPumpMode(
                      tank,
                      PumpMode.manual,
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

class _PumpInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _PumpInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool active;

  const _StatusPill({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : const Color(0xFFF1F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? AppColors.primaryDark : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LeakStatusBanner extends StatelessWidget {
  final int leakCount;
  final VoidCallback onReview;

  const _LeakStatusBanner({required this.leakCount, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final clear = leakCount == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: clear ? const Color(0xFFF0F7FF) : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: clear ? const Color(0xFFDCEBFA) : const Color(0xFFF8D4D4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: clear
                  ? const Color(0xFFE1F2FF)
                  : AppColors.danger.withValues(alpha: 0.1),
            ),
            child: Icon(
              clear ? Icons.water_drop_outlined : Icons.warning_amber_rounded,
              color: clear ? const Color(0xFF1689DD) : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clear
                      ? 'No Leaks Detected'
                      : '$leakCount Water Alert${leakCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clear
                      ? 'All sensors are normal. Keep it up!'
                      : 'Review overflow and leak alerts.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onReview,
            child: Text(clear ? 'View Alerts' : 'Review Alerts'),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final List<WaterTank> tanks;

  const _UsageCard({required this.tanks});

  @override
  Widget build(BuildContext context) {
    final totalEnergy = tanks.fold<double>(
      0,
      (sum, tank) => sum + tank.energyUsageKwh,
    );
    final runtimeMinutes = tanks.fold<int>(
      0,
      (sum, tank) => sum + tank.displayedRunDuration.inMinutes,
    );
    final estimatedLitres = runtimeMinutes * 115;
    const bars = [
      0.25,
      0.4,
      0.3,
      0.55,
      0.42,
      0.7,
      0.52,
      0.4,
      0.3,
      0.75,
      0.58,
      0.68,
      0.45,
      0.35,
      0.27,
      0.5,
      0.62,
      0.83,
      0.7,
      0.55,
    ];

    return _WhiteSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: "Today's Usage"),
          const SizedBox(height: 10),
          Text(
            '${estimatedLitres.toStringAsFixed(0)} L',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pump energy ${totalEnergy.toStringAsFixed(2)} kWh',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (value) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FractionallySizedBox(
                          heightFactor: value,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 AM',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
              Text(
                '6 AM',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
              Text(
                '12 PM',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
              Text(
                '6 PM',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
              Text(
                '12 AM',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final int overflowAlerts;
  final VoidCallback onAlerts;

  const _QuickActionsCard({
    required this.overflowAlerts,
    required this.onAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Quick Actions'),
          const SizedBox(height: 4),
          _QuickActionTile(
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF1689DD),
            title: 'Check Water Alerts',
            subtitle: 'View leak and overflow status',
            onTap: onAlerts,
          ),
          _QuickActionTile(
            icon: Icons.waves_rounded,
            color: AppColors.warning,
            title: 'Overflow Alerts',
            subtitle: overflowAlerts == 0
                ? 'No active overflow alerts'
                : '$overflowAlerts active alert${overflowAlerts == 1 ? '' : 's'}',
            onTap: onAlerts,
          ),
          const _QuickActionTile(
            icon: Icons.schedule_rounded,
            color: AppColors.primary,
            title: 'Pump Schedule',
            subtitle: 'Auto mode follows tank thresholds',
          ),
          const _QuickActionTile(
            icon: Icons.bar_chart_rounded,
            color: Color(0xFF8B5CF6),
            title: 'Usage Reports',
            subtitle: 'Review runtime and energy usage',
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textFaint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _WaterAssistantStrip extends StatelessWidget {
  const _WaterAssistantStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7EFEB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/water_assistant_robot_ref.png',
              width: 65,
              height: 58,
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
                  'Need help with water system?',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ask Homez for tips or support.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: const Text('Ask Homez'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;

  const _CardHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _WhiteSectionCard extends StatelessWidget {
  final Widget child;

  const _WhiteSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyWaterState extends StatelessWidget {
  const _EmptyWaterState();

  @override
  Widget build(BuildContext context) {
    return _WhiteSectionCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No water tanks configured',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add a tank or water system to start monitoring levels and pumps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
