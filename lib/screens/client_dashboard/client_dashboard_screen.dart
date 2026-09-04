import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../models/client_dashboard_model.dart';
import '../../models/device.dart';
import '../../models/property_hierarchy.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_dashboard_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/water_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';
import '../../widgets/app_state_widgets.dart';
import '../alerts/alerts_screen.dart';
import '../devices/devices_screen.dart';
import '../energy/energy_screen.dart';
import '../properties/homes_screen.dart';
import '../water/water_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final auth = context.read<AuthProvider>();
    final properties = context.read<PropertyProvider>().properties;
    if (auth.resolvedClientUuid == null || properties.isEmpty) return;
    await context.read<ClientDashboardProvider>().load(
      clientId: auth.resolvedClientUuid!,
      homeId: properties.first.id,
    );
  }

  Future<void> _load({String? homeId, String? period}) async {
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<ClientDashboardProvider>();
    final selectedHome = homeId ?? dashboard.homeId;
    if (auth.resolvedClientUuid == null || selectedHome == null) return;
    await dashboard.load(
      clientId: auth.resolvedClientUuid!,
      homeId: selectedHome,
      period: period,
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>();
    final provider = context.watch<ClientDashboardProvider>();
    final devices = context.watch<DeviceProvider>();
    final alerts = context.watch<AlertProvider>();
    final water = context.watch<WaterProvider>();
    final selectedHomeId =
        provider.homeId ??
        (properties.properties.isNotEmpty
            ? properties.properties.first.id
            : null);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFC),
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => AppNavigationLeading.drawer(
            color: AppColors.textPrimary,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Client Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Overview of your properties and systems',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Alerts',
                onPressed: () => _push(const AlertsScreen()),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              if (alerts.activeAlerts.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 4,
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
                      alerts.activeAlerts.length > 9
                          ? '9+'
                          : '${alerts.activeAlerts.length}',
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
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              _FilterBar(
                properties: properties,
                selectedHomeId: selectedHomeId,
                provider: provider,
                onHomeChanged: (value) {
                  if (value != null) _load(homeId: value);
                },
                onPeriodChanged: (value) => _load(period: value),
              ),
              const SizedBox(height: 14),
              if (properties.isLoading && properties.properties.isEmpty)
                const _LoadingBlock()
              else if (properties.properties.isEmpty)
                const AppStateCard.empty(
                  title: 'No homes available',
                  message:
                      'Add or sync a client home before opening the dashboard.',
                )
              else if (provider.isLoading && provider.dashboard == null)
                const _LoadingBlock()
              else if (provider.errorMessage != null &&
                  provider.dashboard == null)
                AppStateCard.error(
                  title: 'Dashboard unavailable',
                  message: provider.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              else if (provider.dashboard != null) ...[
                if (provider.errorMessage != null)
                  _InlineError(message: provider.errorMessage!, onRetry: _load),
                _DashboardContent(
                  data: provider.dashboard!,
                  properties: properties,
                  devices: devices,
                  alerts: alerts,
                  water: water,
                  selectedHomeId: selectedHomeId,
                  onEnergyTap: () => _push(const EnergyScreen()),
                  onWaterTap: () => _push(const WaterScreen()),
                  onDevicesTap: () => _push(const DevicesScreen()),
                  onAlertsTap: () => _push(const AlertsScreen()),
                  onPropertiesTap: () => _push(const HomesScreen()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final PropertyProvider properties;
  final String? selectedHomeId;
  final ClientDashboardProvider provider;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<String> onPeriodChanged;

  const _FilterBar({
    required this.properties,
    required this.selectedHomeId,
    required this.provider,
    required this.onHomeChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateRangeLabel(provider.dashboard);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final propertyPicker = _PropertyPicker(
          properties: properties,
          selectedHomeId: selectedHomeId,
          onChanged: onHomeChanged,
        );
        final periodPicker = _PeriodPicker(
          label: dateLabel,
          selectedPeriod: provider.period,
          onChanged: onPeriodChanged,
        );

        if (compact) {
          return Row(
            children: [
              Expanded(child: propertyPicker),
              const SizedBox(width: 10),
              Expanded(child: periodPicker),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 270, child: propertyPicker),
            const Spacer(),
            SizedBox(width: 245, child: periodPicker),
          ],
        );
      },
    );
  }

  static String _dateRangeLabel(ClientDashboardModel? data) {
    if (data?.from != null && data?.to != null) {
      final from = data!.from!.toLocal();
      final to = data.to!.toLocal();
      if (from.year == to.year && from.month == to.month) {
        return '${DateFormat('MMM d').format(from)} – ${DateFormat('MMM d, yyyy').format(to)}';
      }
      return '${DateFormat('MMM d').format(from)} – ${DateFormat('MMM d').format(to)}';
    }
    return _periodLabel(data?.period ?? 'daily');
  }
}

class _PropertyPicker extends StatelessWidget {
  final PropertyProvider properties;
  final String? selectedHomeId;
  final ValueChanged<String?> onChanged;

  const _PropertyPicker({
    required this.properties,
    required this.selectedHomeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _softCardDecoration(radius: 18),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedHomeId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
          borderRadius: BorderRadius.circular(18),
          items: properties.properties
              .map(
                (home) => DropdownMenuItem<String>(
                  value: home.id,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          home.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  final String label;
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodPicker({
    required this.label,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      initialValue: selectedPeriod,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'hourly', child: Text('Hourly')),
        PopupMenuItem(value: 'daily', child: Text('Daily')),
        PopupMenuItem(value: 'weekly', child: Text('Weekly')),
        PopupMenuItem(value: 'monthly', child: Text('Monthly')),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _softCardDecoration(radius: 18),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ClientDashboardModel data;
  final PropertyProvider properties;
  final DeviceProvider devices;
  final AlertProvider alerts;
  final WaterProvider water;
  final String? selectedHomeId;
  final VoidCallback onEnergyTap;
  final VoidCallback onWaterTap;
  final VoidCallback onDevicesTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onPropertiesTap;

  const _DashboardContent({
    required this.data,
    required this.properties,
    required this.devices,
    required this.alerts,
    required this.water,
    required this.selectedHomeId,
    required this.onEnergyTap,
    required this.onWaterTap,
    required this.onDevicesTap,
    required this.onAlertsTap,
    required this.onPropertiesTap,
  });

  @override
  Widget build(BuildContext context) {
    final averageTankLevel = water.tanks.isEmpty
        ? null
        : water.tanks.map((e) => e.levelPercent).reduce((a, b) => a + b) /
              water.tanks.length;

    return Column(
      children: [
        _SummaryGrid(
          propertiesCount: properties.properties.length,
          devicesCount: devices.totalCount,
          energy: data.totalKwh,
          averageWaterLevel: averageTankLevel,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            final energy = _EnergyConsumptionCard(
              data: data,
              onTap: onEnergyTap,
            );
            final waterCard = _WaterStatusCard(water: water, onTap: onWaterTap);
            if (twoColumns) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: energy),
                  const SizedBox(width: 12),
                  Expanded(child: waterCard),
                ],
              );
            }
            return Column(
              children: [energy, const SizedBox(height: 12), waterCard],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 560;
            final deviceStatus = _DeviceStatusCard(
              devices: devices,
              onTap: onDevicesTap,
            );
            final alertsCard = _AlertsOverviewCard(
              alerts: alerts,
              onTap: onAlertsTap,
            );
            if (twoColumns) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: deviceStatus),
                  const SizedBox(width: 12),
                  Expanded(child: alertsCard),
                ],
              );
            }
            return Column(
              children: [deviceStatus, const SizedBox(height: 12), alertsCard],
            );
          },
        ),
        const SizedBox(height: 12),
        _PropertiesPerformanceCard(
          properties: properties,
          devices: devices,
          data: data,
          selectedHomeId: selectedHomeId,
          onTap: onPropertiesTap,
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final int propertiesCount;
  final int devicesCount;
  final double energy;
  final double? averageWaterLevel;

  const _SummaryGrid({
    required this.propertiesCount,
    required this.devicesCount,
    required this.energy,
    required this.averageWaterLevel,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryMetric(
        icon: Icons.apartment_rounded,
        label: 'Total Properties',
        value: '$propertiesCount',
        helper: 'Managed properties',
        helperIcon: Icons.trending_up_rounded,
      ),
      _SummaryMetric(
        icon: Icons.desktop_windows_rounded,
        label: 'Total Devices',
        value: '$devicesCount',
        helper: 'Connected inventory',
        helperIcon: Icons.trending_up_rounded,
      ),
      _SummaryMetric(
        icon: Icons.bolt_rounded,
        label: 'Energy Usage',
        value: _compactNumber(energy),
        unit: 'kWh',
        helper: 'Selected period',
        helperIcon: Icons.energy_savings_leaf_rounded,
      ),
      _SummaryMetric(
        icon: Icons.water_drop_rounded,
        label: 'Water Level',
        value: averageWaterLevel == null
            ? '—'
            : averageWaterLevel!.toStringAsFixed(0),
        unit: averageWaterLevel == null ? '' : '%',
        helper: averageWaterLevel == null
            ? 'No tank data'
            : 'Average tank level',
        helperIcon: Icons.water_drop_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String helper;
  final IconData helperIcon;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    required this.helper,
    required this.helperIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 155),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 13),
      decoration: _softCardDecoration(radius: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(helperIcon, size: 11, color: AppColors.primary),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  helper,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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

class _EnergyConsumptionCard extends StatelessWidget {
  final ClientDashboardModel data;
  final VoidCallback onTap;

  const _EnergyConsumptionCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final values = data.dataPoints;
    final maxY = values.isEmpty
        ? 1.0
        : (values.reduce((a, b) => a > b ? a : b) * 1.25)
              .clamp(1.0, double.infinity)
              .toDouble();

    return _DashboardCard(
      title: 'Energy Consumption (kWh)',
      onViewAll: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: _compactNumber(data.totalKwh),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: ' kWh',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '   ${_periodLabel(data.period)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: values.isEmpty
                ? const _EmptyChart(message: 'No energy data available')
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFEEF2F3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: true),
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
                            reservedSize: 30,
                            getTitlesWidget: (value, _) => Text(
                              _axisNumber(value),
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.labels.length) {
                                return const SizedBox.shrink();
                              }
                              final step = data.labels.length > 7 ? 2 : 1;
                              if (index % step != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data.labels[index],
                                  overflow: TextOverflow.clip,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        values.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: values[index],
                              width: values.length > 10 ? 8 : 14,
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _InfoPill(
            icon: Icons.energy_savings_leaf_rounded,
            text:
                '₹${data.totalCost.toStringAsFixed(2)} estimated cost this period',
          ),
        ],
      ),
    );
  }
}

class _WaterStatusCard extends StatelessWidget {
  final WaterProvider water;
  final VoidCallback onTap;

  const _WaterStatusCard({required this.water, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tanks = water.tanks;
    final average = tanks.isEmpty
        ? 0.0
        : tanks.map((e) => e.levelPercent).reduce((a, b) => a + b) /
              tanks.length;

    return _DashboardCard(
      title: 'Water Tank Levels (%)',
      onViewAll: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: tanks.isEmpty ? '—' : average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (tanks.isNotEmpty)
                  const TextSpan(
                    text: ' %',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                const TextSpan(
                  text: '   Average',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: tanks.isEmpty
                ? const _EmptyChart(message: 'No water tank data available')
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      minX: 0,
                      maxX: (tanks.length - 1)
                          .toDouble()
                          .clamp(1.0, double.infinity)
                          .toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFEEF2F3),
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
                            reservedSize: 30,
                            interval: 25,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index < 0 || index >= tanks.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  width: 50,
                                  child: Text(
                                    tanks[index].name
                                        .split(' ')
                                        .take(2)
                                        .join(' '),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            tanks.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              tanks[index].levelPercent,
                            ),
                          ),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppColors.primary,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.18),
                                AppColors.primary.withValues(alpha: 0.01),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _InfoPill(
            icon: Icons.water_drop_rounded,
            text: tanks.isEmpty
                ? 'Water monitoring is waiting for tank data'
                : '${tanks.length} water system${tanks.length == 1 ? '' : 's'} monitored',
          ),
        ],
      ),
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  final DeviceProvider devices;
  final VoidCallback onTap;

  const _DeviceStatusCard({required this.devices, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = devices.totalCount;
    final online = devices.onlineCount;
    final offline = devices.offlineCount;
    final other = (total - online - offline).clamp(0, total).toInt();

    double pct(int value) => total == 0 ? 0 : value / total;

    return _DashboardCard(
      title: 'Device Status',
      onViewAll: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 175,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 40,
                          sectionsSpace: 0,
                          startDegreeOffset: -90,
                          sections: total == 0
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color: AppColors.divider,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                ]
                              : [
                                  PieChartSectionData(
                                    value: online.toDouble(),
                                    color: AppColors.primary,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: offline.toDouble(),
                                    color: AppColors.warning,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: other.toDouble(),
                                    color: AppColors.danger,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendRow(
                        label: 'Online',
                        value: online,
                        percentage: pct(online),
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(
                        label: 'Offline',
                        value: offline,
                        percentage: pct(offline),
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(
                        label: 'Alert',
                        value: other,
                        percentage: pct(other),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _InfoPill(
            icon: online == total && total > 0
                ? Icons.verified_user_rounded
                : Icons.info_outline_rounded,
            text: total == 0
                ? 'No devices currently registered'
                : online == total
                ? 'All systems are operational'
                : '$online of $total devices are online',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int value;
  final double percentage;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          ),
        ),
        Text(
          '$value (${(percentage * 100).round()}%)',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AlertsOverviewCard extends StatelessWidget {
  final AlertProvider alerts;
  final VoidCallback onTap;

  const _AlertsOverviewCard({required this.alerts, required this.onTap});

  int _count(AlertType type) =>
      alerts.activeAlerts.where((a) => a.alertType == type).length;

  @override
  Widget build(BuildContext context) {
    final smoke = _count(AlertType.smoke);
    final gas = _count(AlertType.gasLeak);
    final water = _count(AlertType.waterOverflow);
    final other = alerts.activeAlerts.length - smoke - gas - water;

    return _DashboardCard(
      title: 'Alerts Overview',
      onViewAll: onTap,
      child: Column(
        children: [
          _AlertRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.danger,
            bgColor: const Color(0xFFFFEEEE),
            title: 'Fire / Smoke',
            count: smoke,
          ),
          _AlertRow(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF6E5),
            title: 'Gas Leakage',
            count: gas,
          ),
          _AlertRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF1D9BF0),
            bgColor: const Color(0xFFE8F5FF),
            title: 'Water Overflow',
            count: water,
          ),
          _AlertRow(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            bgColor: const Color(0xFFFFF8DD),
            title: 'Other Alerts',
            count: other.clamp(0, alerts.activeAlerts.length).toInt(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.verified_user_rounded, size: 16),
              label: const Text('View All Alerts'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final int count;

  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFC),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$count Active Alert${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: count > 0 ? iconColor : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertiesPerformanceCard extends StatelessWidget {
  final PropertyProvider properties;
  final DeviceProvider devices;
  final ClientDashboardModel data;
  final String? selectedHomeId;
  final VoidCallback onTap;

  const _PropertiesPerformanceCard({
    required this.properties,
    required this.devices,
    required this.data,
    required this.selectedHomeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Properties Performance',
      onViewAll: onTap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 580,
          child: Column(
            children: [
              const _PropertyHeaderRow(),
              const Divider(height: 10, color: AppColors.divider),
              if (properties.properties.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No properties available'),
                )
              else
                ...properties.properties
                    .take(5)
                    .map(
                      (property) => _PropertyPerformanceRow(
                        property: property,
                        isSelected: property.id == selectedHomeId,
                        energy: property.id == selectedHomeId
                            ? data.totalKwh
                            : null,
                        devicesCount: _devicesForProperty(property).length,
                        allGood: _devicesForProperty(
                          property,
                        ).every((device) => device.status.name == 'online'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<Device> _devicesForProperty(ManagedProperty property) {
    return devices.devices.where((device) {
      return device.buildingId == property.id ||
          (device.homeName?.trim().toLowerCase() ==
              property.name.trim().toLowerCase());
    }).toList();
  }
}

class _PropertyHeaderRow extends StatelessWidget {
  const _PropertyHeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 9.5,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    return const Row(
      children: [
        SizedBox(width: 205, child: Text('Property', style: style)),
        SizedBox(width: 105, child: Text('Energy (kWh)', style: style)),
        SizedBox(width: 85, child: Text('Devices', style: style)),
        Expanded(child: Text('Status', style: style)),
      ],
    );
  }
}

class _PropertyPerformanceRow extends StatelessWidget {
  final ManagedProperty property;
  final bool isSelected;
  final double? energy;
  final int devicesCount;
  final bool allGood;

  const _PropertyPerformanceRow({
    required this.property,
    required this.isSelected,
    required this.energy,
    required this.devicesCount,
    required this.allGood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F4F5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 205,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    property.propertyType.toLowerCase().contains('apartment')
                        ? Icons.apartment_rounded
                        : Icons.home_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    property.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 105,
            child: Text(
              energy == null ? '—' : energy!.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 85,
            child: Text(
              '$devicesCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: allGood ? AppColors.primary : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  devicesCount == 0
                      ? 'No devices'
                      : allGood
                      ? 'All Good'
                      : 'Check',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: allGood ? AppColors.primary : AppColors.warning,
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _softCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

BoxDecoration _softCardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE9EFF0)),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 5)),
    ],
  );
}

String _periodLabel(String period) {
  switch (period.toLowerCase()) {
    case 'hourly':
      return 'This Hour';
    case 'weekly':
      return 'This Week';
    case 'monthly':
      return 'This Month';
    case 'daily':
    default:
      return 'Today';
  }
}

String _compactNumber(double value) {
  if (value.abs() >= 1000) return value.toStringAsFixed(0);
  if (value.abs() >= 100) return value.toStringAsFixed(1);
  return value.toStringAsFixed(2);
}

String _axisNumber(double value) {
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  if (value.abs() >= 100) return value.toStringAsFixed(0);
  if (value.abs() >= 10) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
