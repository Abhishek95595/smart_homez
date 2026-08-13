import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_dashboard_model.dart';
import '../../models/property_hierarchy.dart';
import '../../providers/auth_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/app_state_widgets.dart';

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
        setState(() {
          _selectedHomeId = properties.first.id;
        });
        _fetchData();
      }
    });
  }

  void _fetchData() {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId != null && _selectedHomeId != null) {
      context.read<EnergyProvider>().fetchDashboard(
            clientId: clientId,
            homeId: _selectedHomeId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = context.watch<EnergyProvider>();
    final properties = context.watch<PropertyProvider>().properties;
    final dashboard = energyProvider.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Gen-Z Cyber Energy Hero AppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0B0F19),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Energy Matrix',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              background: _CyberEnergyHero(
                liveWatts: energyProvider.instantPowerWatts,
                source: dashboard?.currentPowerSource ?? 'Grid Active',
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  // Property & Period Selector
                  _SelectionHeader(
                    properties: properties,
                    selectedHomeId: _selectedHomeId,
                    selectedPeriod: energyProvider.selectedPeriod,
                    onHomeChanged: (id) {
                      if (id == null) return;
                      setState(() => _selectedHomeId = id);
                      _fetchData();
                    },
                    onPeriodChanged: (period) {
                      energyProvider.setSelectedPeriod(period);
                      _fetchData();
                    },
                  ),
                  const SizedBox(height: 16),

                  if (energyProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: AppLoadingState(
                          message: 'Synchronizing telemetry matrix…'),
                    )
                  else if (energyProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      child: AppStateCard.error(
                        title: 'Telemetry Connection Interrupted',
                        message: energyProvider.error!,
                        actionLabel: 'Re-sync Data',
                        onAction: _fetchData,
                      ),
                    )
                  else if (dashboard == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: AppStateCard.empty(
                        title: 'No Telemetry Available',
                        message: 'Select a property to stream real-time analytics.',
                      ),
                    )
                  else
                    _DashboardContent(
                      dashboard: dashboard,
                      period: energyProvider.selectedPeriod,
                      consumptionLabel: energyProvider.consumptionLabel,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberEnergyHero extends StatelessWidget {
  final double liveWatts;
  final String source;

  const _CyberEnergyHero({
    required this.liveWatts,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF070B14), Color(0xFF0F172A), Color(0xFF134E4A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient neon radial glows
          Positioned(
            top: 20,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Central live telemetry display
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Live Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C9A7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00C9A7),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'REAL-TIME POWER LOAD',
                        style: TextStyle(
                          color: Color(0xFF00C9A7),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Big Dynamic Wattage Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      liveWatts.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'WATTS',
                      style: TextStyle(
                        color: Color(0xFF00C9A7),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subtitle Status Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '⚡ SOURCE: ${source.toUpperCase()} • 96% OPTIMAL',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.properties,
    required this.selectedHomeId,
    required this.selectedPeriod,
    required this.onHomeChanged,
    required this.onPeriodChanged,
  });

  final List<ManagedProperty> properties;
  final String? selectedHomeId;
  final DashboardPeriod selectedPeriod;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Clean Property Selector Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedHomeId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF00A38E)),
              hint: const Text(
                'Select Monitored Space',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              items: properties.map((property) {
                return DropdownMenuItem<String>(
                  value: property.id,
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_rounded,
                          size: 18, color: Color(0xFF00A38E)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          property.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
              onChanged: properties.isEmpty ? null : onHomeChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Period Switcher Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: DashboardPeriod.values.map((period) {
              final isSelected = period == selectedPeriod;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
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
                      borderRadius: BorderRadius.circular(12),
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
                    child: Text(
                      _shortLabel(period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _shortLabel(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.hourly:
        return '24 Hours';
      case DashboardPeriod.daily:
        return '30 Days';
      case DashboardPeriod.weekly:
        return '12 Weeks';
      case DashboardPeriod.monthly:
        return '12 Months';
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.period,
    required this.consumptionLabel,
  });

  final ClientDashboardModel dashboard;
  final DashboardPeriod period;
  final String consumptionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2x2 Cyber Metric Matrix
        Row(
          children: [
            Expanded(
              child: _GenZMetricTile(
                label: consumptionLabel,
                value: '${dashboard.totalKwh.toStringAsFixed(1)} kWh',
                icon: Icons.bolt_rounded,
                accentColor: const Color(0xFF00C9A7),
                bgGradient: const [Color(0xFFF0FDFB), Colors.white],
                badgeText: 'Total Used',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenZMetricTile(
                label: 'Active Source',
                value: dashboard.currentPowerSource,
                icon: Icons.power_rounded,
                accentColor: const Color(0xFFF59E0B),
                bgGradient: const [Color(0xFFFFFBEB), Colors.white],
                badgeText: 'Live Stream',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _GenZMetricTile(
                label: 'Grid Consumption',
                value: '${dashboard.gridKwh.toStringAsFixed(1)} kWh',
                icon: Icons.electric_bolt_rounded,
                accentColor: const Color(0xFF3B82F6),
                bgGradient: const [Color(0xFFEFF6FF), Colors.white],
                badgeText: 'Main Line',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenZMetricTile(
                label: 'Backup Energy',
                value: '${dashboard.backupKwh.toStringAsFixed(1)} kWh',
                icon: Icons.battery_charging_full_rounded,
                accentColor: const Color(0xFFF97316),
                bgGradient: const [Color(0xFFFFF7ED), Colors.white],
                badgeText: 'Inverter / DG',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Estimated Cost Banner with Eco Savings
        _CostAndSavingsBanner(
          cost: dashboard.totalCost,
          kwh: dashboard.totalKwh,
        ),
        const SizedBox(height: 24),

        // Primary Consumption Bar Chart
        _SectionTitle(
          title: '${period.label} Consumption Trend',
          subtitle: 'Detailed period breakdown & peak telemetry',
        ),
        const SizedBox(height: 14),
        _ConsumptionChart(
          labels: dashboard.labels,
          points: dashboard.dataPoints,
          color: const Color(0xFF00A38E),
        ),
        const SizedBox(height: 28),

        // Dual Line Grid vs Backup Chart
        const _SectionTitle(
          title: 'Grid vs Backup Trajectory',
          subtitle: 'Dual-series comparative telemetry (kWh)',
        ),
        const SizedBox(height: 14),
        _DualLineChart(
          labels: dashboard.labels,
          gridPoints: dashboard.gridData,
          backupPoints: dashboard.backupData,
        ),
        const SizedBox(height: 28),

        // Eco Green Footprint Card
        _EcoFootprintCard(totalKwh: dashboard.totalKwh),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GenZMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final List<Color> bgGradient;
  final String badgeText;

  const _GenZMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgGradient,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostAndSavingsBanner extends StatelessWidget {
  final double cost;
  final double kwh;

  const _CostAndSavingsBanner({required this.cost, required this.kwh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.currency_rupee_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED BILL IMPACT',
                  style: TextStyle(
                    color: Color(0xFF00C9A7),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹ ${cost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_down_rounded,
                    size: 14, color: Color(0xFF6EE7B7)),
                SizedBox(width: 4),
                Text(
                  '8% Eco Save',
                  style: TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({
    required this.labels,
    required this.points,
    required this.color,
  });

  final List<String> labels;
  final List<double> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data points')),
      );
    }

    final usableLength =
        points.length < labels.length ? points.length : labels.length;

    if (usableLength == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No chart data available')),
      );
    }

    final chartPoints = points.take(usableLength).toList(growable: false);
    final chartLabels = labels.take(usableLength).toList(growable: false);

    final maxValue = chartPoints.reduce((a, b) => a > b ? a : b);
    final total = chartPoints.fold<double>(0, (sum, point) => sum + point);
    final average = total / chartPoints.length;
    final labelInterval = (chartLabels.length / 5).ceil().clamp(1, 999);

    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chartHeaderStat('TOTAL VOLUME', '${total.toStringAsFixed(1)} kWh'),
              _chartHeaderStat('AVERAGE LOAD', '${average.toStringAsFixed(1)} kWh'),
              _chartHeaderStat(
                'PEAK DEMAND',
                '${maxValue.toStringAsFixed(1)} kWh',
                isPeak: true,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue == 0 ? 1 : maxValue * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= chartLabels.length) {
                        return null;
                      }
                      return BarTooltipItem(
                        '${chartLabels[groupIndex]}\n',
                        const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(1)} kWh',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 3,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= chartLabels.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            chartLabels[index],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(chartPoints.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: chartPoints[index],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartHeaderStat(String label, String value, {bool isPeak = false}) {
    return Column(
      crossAxisAlignment:
          isPeak ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isPeak ? const Color(0xFF00A38E) : const Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: isPeak ? const Color(0xFF00A38E) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _DualLineChart extends StatelessWidget {
  const _DualLineChart({
    required this.labels,
    required this.gridPoints,
    required this.backupPoints,
  });

  final List<String> labels;
  final List<double> gridPoints;
  final List<double> backupPoints;

  @override
  Widget build(BuildContext context) {
    if (gridPoints.isEmpty && backupPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxSeriesLength = gridPoints.length > backupPoints.length
        ? gridPoints.length
        : backupPoints.length;

    final usableLength =
        labels.length < maxSeriesLength ? labels.length : maxSeriesLength;

    if (usableLength == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No comparison data available')),
      );
    }

    final chartLabels = labels.take(usableLength).toList(growable: false);
    final chartGridPoints =
        gridPoints.take(usableLength).toList(growable: false);
    final chartBackupPoints =
        backupPoints.take(usableLength).toList(growable: false);

    final labelInterval = (chartLabels.length / 4).ceil().clamp(1, 999);

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('Main Grid Line', const Color(0xFF3B82F6)),
              const SizedBox(width: 24),
              _legend('Backup Source', const Color(0xFFF97316)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: usableLength > 1 ? (usableLength - 1).toDouble() : 1,
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= chartLabels.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            chartLabels[index],
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  if (chartGridPoints.isNotEmpty)
                    LineChartBarData(
                      spots: List.generate(
                        chartGridPoints.length,
                        (index) =>
                            FlSpot(index.toDouble(), chartGridPoints[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFF3B82F6),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      ),
                    ),
                  if (chartBackupPoints.isNotEmpty)
                    LineChartBarData(
                      spots: List.generate(
                        chartBackupPoints.length,
                        (index) =>
                            FlSpot(index.toDouble(), chartBackupPoints[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFFF97316),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFF97316).withValues(alpha: 0.08),
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

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _EcoFootprintCard extends StatelessWidget {
  final double totalKwh;

  const _EcoFootprintCard({required this.totalKwh});

  @override
  Widget build(BuildContext context) {
    final co2Kg = (totalKwh * 0.82).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF059669),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ECO FOOTPRINT & OFFSET',
                  style: TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$co2Kg kg CO₂ Impact',
                  style: const TextStyle(
                    color: Color(0xFF064E3B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Optimal efficiency keeps your property within target green standards.',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
