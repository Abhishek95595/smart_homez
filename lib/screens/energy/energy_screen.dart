import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/client_dashboard_model.dart';
import '../../models/property_hierarchy.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_state_widgets.dart';
import '../alerts/alerts_screen.dart';

class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  String? _selectedHomeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final properties = context.read<PropertyProvider>().properties;
      if (properties.isNotEmpty) {
        setState(() => _selectedHomeId = properties.first.id);
        _fetchData();
      }
    });
  }

  void _fetchData() {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId == null || _selectedHomeId == null) return;
    context.read<EnergyProvider>().fetchDashboard(
      clientId: clientId,
      homeId: _selectedHomeId!,
    );
  }

  void _showComparison(ClientDashboardModel dashboard) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final total = dashboard.gridKwh + dashboard.backupKwh;
        final gridShare = total <= 0 ? 0.0 : dashboard.gridKwh / total * 100;
        final backupShare = total <= 0
            ? 0.0
            : dashboard.backupKwh / total * 100;
        return _BottomInfoSheet(
          title: 'Energy source comparison',
          icon: Icons.compare_arrows_rounded,
          children: [
            _ComparisonRow(
              label: 'Grid',
              value: '${dashboard.gridKwh.toStringAsFixed(1)} kWh',
              share: gridShare,
              icon: Icons.electric_bolt_rounded,
              color: const Color(0xFF089981),
            ),
            const SizedBox(height: 14),
            _ComparisonRow(
              label: 'Backup',
              value: '${dashboard.backupKwh.toStringAsFixed(1)} kWh',
              share: backupShare,
              icon: Icons.battery_charging_full_rounded,
              color: const Color(0xFF3B82F6),
            ),
          ],
        );
      },
    );
  }

  void _showInsights(ClientDashboardModel dashboard) {
    final stats = _EnergyStats.fromDashboard(dashboard);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BottomInfoSheet(
        title: 'Energy insights',
        icon: Icons.lightbulb_outline_rounded,
        children: [
          _InsightLine(
            icon: Icons.query_stats_rounded,
            title: 'Average usage',
            text: '${stats.average.toStringAsFixed(2)} kWh per data point',
          ),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.trending_up_rounded,
            title: 'Peak usage',
            text: stats.peakLabel.isEmpty
                ? '${stats.peak.toStringAsFixed(2)} kWh'
                : '${stats.peak.toStringAsFixed(2)} kWh at ${stats.peakLabel}',
          ),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.currency_rupee_rounded,
            title: 'Estimated cost',
            text: '₹${dashboard.totalCost.toStringAsFixed(2)} for this period',
          ),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.power_rounded,
            title: 'Current source',
            text: dashboard.currentPowerSource,
          ),
        ],
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BottomInfoSheet(
        title: 'Energy saving tips',
        icon: Icons.tips_and_updates_outlined,
        children: [
          _InsightLine(
            icon: Icons.thermostat_rounded,
            title: 'Optimize cooling',
            text: 'Keep AC temperature around 24°C when comfortable.',
          ),
          SizedBox(height: 12),
          _InsightLine(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Reduce idle loads',
            text: 'Switch off lights and appliances in unused rooms.',
          ),
          SizedBox(height: 12),
          _InsightLine(
            icon: Icons.schedule_rounded,
            title: 'Use schedules',
            text: 'Automate high-consumption devices around your routine.',
          ),
        ],
      ),
    );
  }

  void _showAssistant() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BottomInfoSheet(
        title: 'Ask Homez',
        icon: Icons.smart_toy_outlined,
        children: [
          Text(
            'Homez can help you understand your current energy pattern and suggest practical automations.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: 16),
          _AssistantPrompt(text: 'Where is most of my energy coming from?'),
          SizedBox(height: 8),
          _AssistantPrompt(text: 'How can I reduce this period’s cost?'),
          SizedBox(height: 8),
          _AssistantPrompt(text: 'Suggest an energy-saving automation.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = context.watch<EnergyProvider>();
    final properties = context.watch<PropertyProvider>().properties;
    final dashboard = energyProvider.dashboard;
    final alertCount = context.watch<AlertProvider>().criticalActiveCount;

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _EnergyHeader(
              alertCount: alertCount,
              onAlerts: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    _TopSelectors(
                      properties: properties,
                      selectedHomeId: _selectedHomeId,
                      dashboard: dashboard,
                      onHomeChanged: (id) {
                        if (id == null) return;
                        setState(() => _selectedHomeId = id);
                        _fetchData();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (energyProvider.isLoading && dashboard == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: AppLoadingState(
                          message: 'Loading energy monitoring…',
                        ),
                      )
                    else if (energyProvider.error != null && dashboard == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 42),
                        child: AppStateCard.error(
                          title: 'Unable to load energy data',
                          message: energyProvider.error!,
                          actionLabel: 'Retry',
                          onAction: _fetchData,
                        ),
                      )
                    else if (dashboard == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 42),
                        child: AppStateCard.empty(
                          title: 'No energy data yet',
                          message:
                              'Select a home to view its energy monitoring.',
                        ),
                      )
                    else ...[
                      _OverviewHero(
                        dashboard: dashboard,
                        onInsights: () => _showInsights(dashboard),
                      ),
                      const SizedBox(height: 14),
                      _PeriodAndCompare(
                        selectedPeriod: energyProvider.selectedPeriod,
                        onPeriodChanged: (period) {
                          energyProvider.setSelectedPeriod(period);
                          _fetchData();
                        },
                        onCompare: () => _showComparison(dashboard),
                      ),
                      const SizedBox(height: 14),
                      _MetricGrid(dashboard: dashboard),
                      const SizedBox(height: 14),
                      _ConsumptionCard(
                        dashboard: dashboard,
                        period: energyProvider.selectedPeriod,
                      ),
                      const SizedBox(height: 14),
                      _LowerAnalytics(dashboard: dashboard),
                      const SizedBox(height: 14),
                      _SavingTip(onTap: _showTips),
                      const SizedBox(height: 14),
                      _AskHomezBanner(onTap: _showAssistant),
                    ],
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

class _EnergyHeader extends StatelessWidget {
  final int alertCount;
  final VoidCallback onAlerts;

  const _EnergyHeader({required this.alertCount, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
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
                  'Energy Monitoring',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track and optimize your energy usage',
                  style: TextStyle(
                    color: Color(0xFF25335D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

class _TopSelectors extends StatelessWidget {
  final List<ManagedProperty> properties;
  final String? selectedHomeId;
  final ClientDashboardModel? dashboard;
  final ValueChanged<String?> onHomeChanged;

  const _TopSelectors({
    required this.properties,
    required this.selectedHomeId,
    required this.dashboard,
    required this.onHomeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = _dateRange(dashboard);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Home',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _HomeDropdown(
                properties: properties,
                selectedHomeId: selectedHomeId,
                onChanged: onHomeChanged,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _DateChip(text: dateText),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Select Home',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HomeDropdown(
                properties: properties,
                selectedHomeId: selectedHomeId,
                onChanged: onHomeChanged,
              ),
            ),
            const SizedBox(width: 12),
            _DateChip(text: dateText),
          ],
        );
      },
    );
  }

  static String _dateRange(ClientDashboardModel? dashboard) {
    if (dashboard?.from == null || dashboard?.to == null) {
      return 'Current period';
    }
    final from = dashboard!.from!.toLocal();
    final to = dashboard.to!.toLocal();
    if (DateUtils.isSameDay(from, to)) {
      return DateFormat('dd MMM yyyy').format(to);
    }
    return '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM yyyy').format(to)}';
  }
}

class _HomeDropdown extends StatelessWidget {
  final List<ManagedProperty> properties;
  final String? selectedHomeId;
  final ValueChanged<String?> onChanged;

  const _HomeDropdown({
    required this.properties,
    required this.selectedHomeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelected = properties.any((item) => item.id == selectedHomeId);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: hasSelected ? selectedHomeId : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF25335D),
          ),
          hint: const Text(
            'Select a home',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          items: properties
              .map(
                (property) => DropdownMenuItem<String>(
                  value: property.id,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: properties.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  const _DateChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF25335D),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF25335D),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  final ClientDashboardModel dashboard;
  final VoidCallback onInsights;

  const _OverviewHero({required this.dashboard, required this.onInsights});

  @override
  Widget build(BuildContext context) {
    final previous = dashboard.yesterdayKwh;
    final delta = previous <= 0
        ? 0.0
        : ((dashboard.totalKwh - previous) / previous) * 100;
    final positive = delta <= 0;
    final co2Estimate = dashboard.totalKwh * 0.82;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Container(
          height: compact ? 250 : 228,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD8EFEB)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -36 : 105,
                bottom: -70,
                width: compact ? 220 : 245,
                height: compact ? 220 : 245,
                child: Opacity(
                  opacity: 0.98,
                  child: Image.asset(
                    'assets/images/smart_robot.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: 22,
                child: Icon(
                  Icons.wind_power_outlined,
                  size: 118,
                  color: AppColors.primary.withValues(alpha: 0.045),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 22, compact ? 142 : 370, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Period's Overview",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dashboard.totalKwh.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 31,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 2),
                          child: Text(
                            'kWh',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Total Energy Consumed',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF25335D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          positive ? Icons.south_rounded : Icons.north_rounded,
                          size: 16,
                          color: positive
                              ? AppColors.primaryDark
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            previous <= 0
                                ? 'Live monitoring active'
                                : '${delta.abs().toStringAsFixed(0)}% ${positive ? 'less' : 'more'} than yesterday',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: positive
                                  ? AppColors.primaryDark
                                  : AppColors.warning,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onInsights,
                        icon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Energy Insights'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          backgroundColor: Colors.white.withValues(alpha: 0.78),
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Positioned(
                  right: 18,
                  top: 34,
                  width: 168,
                  height: 156,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            _RoundIcon(
                              icon: Icons.eco_rounded,
                              color: AppColors.primaryDark,
                              background: AppColors.primarySoft,
                              size: 32,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CO₂ Estimate',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Color(0xFF25335D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${co2Estimate.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Estimated usage footprint',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dashboard.currentPowerSource,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodAndCompare extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final VoidCallback onCompare;

  const _PeriodAndCompare({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    const labels = {
      DashboardPeriod.hourly: 'Hour',
      DashboardPeriod.daily: 'Day',
      DashboardPeriod.weekly: 'Week',
      DashboardPeriod.monthly: 'Month',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final selector = Container(
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: DashboardPeriod.values
                .map((period) {
                  final active = period == selectedPeriod;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onPeriodChanged(period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          labels[period]!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? Colors.white
                                : const Color(0xFF25335D),
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Period',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              selector,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _CompareButton(onTap: onCompare),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: selector),
            const SizedBox(width: 12),
            _CompareButton(onTap: onCompare),
          ],
        );
      },
    );
  }
}

class _CompareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.compare_arrows_rounded, size: 17),
        label: const Text('Compare'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF25335D),
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final ClientDashboardModel dashboard;
  const _MetricGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = _EnergyStats.fromDashboard(dashboard);
    final items = [
      _MetricData(
        icon: Icons.bolt_rounded,
        title: 'Avg. Usage',
        value: '${stats.average.toStringAsFixed(2)} kWh',
        subtitle: 'Per data point',
        color: const Color(0xFF3B82F6),
        background: const Color(0xFFEAF2FF),
      ),
      _MetricData(
        icon: Icons.trending_up_rounded,
        title: 'Peak Usage',
        value: '${stats.peak.toStringAsFixed(2)} kWh',
        subtitle: stats.peakLabel.isEmpty ? 'Peak reading' : stats.peakLabel,
        color: const Color(0xFFE11D48),
        background: const Color(0xFFFFEEF2),
      ),
      _MetricData(
        icon: Icons.currency_rupee_rounded,
        title: 'Total Cost',
        value: '₹${dashboard.totalCost.toStringAsFixed(2)}',
        subtitle: 'Selected period',
        color: AppColors.primaryDark,
        background: AppColors.primarySoft,
      ),
      _MetricData(
        icon: Icons.electric_meter_outlined,
        title: 'Live Power',
        value: '${dashboard.liveWatts.toStringAsFixed(0)} W',
        subtitle: dashboard.currentPowerSource,
        color: const Color(0xFF089981),
        background: const Color(0xFFE7F8F5),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _MetricCard(data: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color background;

  const _MetricData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.background,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundIcon(
                icon: data.icon,
                color: data.color,
                background: data.background,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF25335D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  final ClientDashboardModel dashboard;
  final DashboardPeriod period;

  const _ConsumptionCard({required this.dashboard, required this.period});

  @override
  Widget build(BuildContext context) {
    final count = dashboard.dataPoints.length < dashboard.labels.length
        ? dashboard.dataPoints.length
        : dashboard.labels.length;
    final points = dashboard.dataPoints.take(count).toList(growable: false);
    final labels = dashboard.labels.take(count).toList(growable: false);
    final maxValue = points.isEmpty
        ? 0.0
        : points.reduce((a, b) => a > b ? a : b);
    final interval = (labels.length / 6).ceil().clamp(1, 999);

    return Container(
      height: 310,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Energy Consumption (kWh)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _periodText(period),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF25335D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF25335D),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: points.isEmpty
                ? const Center(
                    child: Text(
                      'No energy readings for this period',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textPrimary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < 0 || groupIndex >= labels.length) {
                              return null;
                            }
                            return BarTooltipItem(
                              '${labels[groupIndex]}\n${rod.toY.toStringAsFixed(1)} kWh',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue <= 0 ? 1 : maxValue / 3,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF0F3F5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              if (index % interval != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[index],
                                  style: const TextStyle(
                                    color: Color(0xFF25335D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(points.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: points[index],
                              color: AppColors.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          if (points.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendSquare(color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Energy (kWh)',
                      style: TextStyle(
                        color: Color(0xFF25335D),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _periodText(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.hourly:
        return 'Last 24 Hours';
      case DashboardPeriod.daily:
        return 'This Month';
      case DashboardPeriod.weekly:
        return 'Recent Weeks';
      case DashboardPeriod.monthly:
        return 'This Year';
    }
  }
}

class _LowerAnalytics extends StatelessWidget {
  final ClientDashboardModel dashboard;
  const _LowerAnalytics({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final mix = _SourceMixCard(dashboard: dashboard);
        final breakdown = _SourceBreakdownCard(dashboard: dashboard);
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mix),
              const SizedBox(width: 12),
              Expanded(child: breakdown),
            ],
          );
        }
        return Column(children: [mix, const SizedBox(height: 12), breakdown]);
      },
    );
  }
}

class _SourceMixCard extends StatelessWidget {
  final ClientDashboardModel dashboard;
  const _SourceMixCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final total = dashboard.gridKwh + dashboard.backupKwh;
    final gridShare = total <= 0 ? 0.0 : dashboard.gridKwh / total;
    final backupShare = total <= 0 ? 0.0 : dashboard.backupKwh / total;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage by Source',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 36,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: gridShare <= 0 ? 0.001 : gridShare,
                            color: AppColors.primary,
                            showTitle: false,
                            radius: 19,
                          ),
                          PieChartSectionData(
                            value: backupShare <= 0 ? 0.001 : backupShare,
                            color: const Color(0xFF3B82F6),
                            showTitle: false,
                            radius: 19,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dashboard.totalKwh.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'kWh',
                          style: TextStyle(
                            color: Color(0xFF25335D),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _MixLegend(
                      color: AppColors.primary,
                      label: 'Grid',
                      value: '${(gridShare * 100).toStringAsFixed(0)}%',
                      kwh: dashboard.gridKwh,
                    ),
                    const SizedBox(height: 15),
                    _MixLegend(
                      color: const Color(0xFF3B82F6),
                      label: 'Backup',
                      value: '${(backupShare * 100).toStringAsFixed(0)}%',
                      kwh: dashboard.backupKwh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double kwh;

  const _MixLegend({
    required this.color,
    required this.label,
    required this.value,
    required this.kwh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value (${kwh.toStringAsFixed(1)} kWh)',
                style: const TextStyle(
                  color: Color(0xFF25335D),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceBreakdownCard extends StatelessWidget {
  final ClientDashboardModel dashboard;
  const _SourceBreakdownCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final max = [
      dashboard.gridKwh,
      dashboard.backupKwh,
      dashboard.totalKwh,
    ].reduce((a, b) => a > b ? a : b);
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Power Source Breakdown',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                dashboard.currentPowerSource,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SourceProgress(
            icon: Icons.electric_bolt_rounded,
            label: 'Grid Energy',
            value: dashboard.gridKwh,
            max: max,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _SourceProgress(
            icon: Icons.battery_charging_full_rounded,
            label: 'Backup Energy',
            value: dashboard.backupKwh,
            max: max,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 14),
          _SourceProgress(
            icon: Icons.swap_horiz_rounded,
            label: 'Switchover Time',
            value: dashboard.switchoverMinutes,
            max: dashboard.switchoverMinutes <= 0
                ? 1
                : dashboard.switchoverMinutes,
            color: const Color(0xFF8B5CF6),
            unit: 'min',
          ),
        ],
      ),
    );
  }
}

class _SourceProgress extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;

  const _SourceProgress({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.unit = 'kWh',
  });

  @override
  Widget build(BuildContext context) {
    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 30, child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF25335D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      color: Color(0xFF25335D),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF0F3F5),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavingTip extends StatelessWidget {
  final VoidCallback onTap;
  const _SavingTip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFEFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEFEB)),
      ),
      child: Row(
        children: [
          const _RoundIcon(
            icon: Icons.lightbulb_outline_rounded,
            color: Color(0xFFF59E0B),
            background: Color(0xFFFFF6DD),
            size: 42,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Energy Saving Tip',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Set your AC temperature to 24°C when comfortable.',
                  style: TextStyle(
                    color: Color(0xFF25335D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Small adjustments can reduce unnecessary power usage.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: const Text('View Tips', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _AskHomezBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AskHomezBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7EEEA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 82,
            child: Image.asset(
              'assets/images/smart_robot.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask Homez',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'How can I help you save more energy today?',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF25335D),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 25,
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

class _EnergyStats {
  final double average;
  final double peak;
  final String peakLabel;

  const _EnergyStats({
    required this.average,
    required this.peak,
    required this.peakLabel,
  });

  factory _EnergyStats.fromDashboard(ClientDashboardModel dashboard) {
    if (dashboard.dataPoints.isEmpty) {
      return const _EnergyStats(average: 0, peak: 0, peakLabel: '');
    }
    final total = dashboard.dataPoints.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    var peak = dashboard.dataPoints.first;
    var peakIndex = 0;
    for (var i = 1; i < dashboard.dataPoints.length; i++) {
      if (dashboard.dataPoints[i] > peak) {
        peak = dashboard.dataPoints[i];
        peakIndex = i;
      }
    }
    final label = peakIndex < dashboard.labels.length
        ? dashboard.labels[peakIndex]
        : '';
    return _EnergyStats(
      average: total / dashboard.dataPoints.length,
      peak: peak,
      peakLabel: label,
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const _RoundIcon({
    required this.icon,
    required this.color,
    required this.background,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.54),
    );
  }
}

class _LegendSquare extends StatelessWidget {
  final Color color;
  const _LegendSquare({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BottomInfoSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _BottomInfoSheet({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _RoundIcon(
                icon: icon,
                color: AppColors.primaryDark,
                background: AppColors.primarySoft,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value;
  final double share;
  final IconData icon;
  final Color color;

  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.share,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIcon(
          icon: icon,
          color: color,
          background: color.withValues(alpha: 0.1),
          size: 42,
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
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (share / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${share.toStringAsFixed(0)}% of source energy',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InsightLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssistantPrompt extends StatelessWidget {
  final String text;
  const _AssistantPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD3EEEA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryDark,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF25335D),
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
