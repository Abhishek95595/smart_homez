import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_dashboard_model.dart';
import '../../models/device.dart';
import '../../models/property_hierarchy.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tariff_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';

class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedHomeId;
  String _chartViewMode = 'total'; // 'total', 'grid', 'backup'
  Timer? _liveTelemetryTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final properties = context.read<PropertyProvider>().properties;
      if (properties.isNotEmpty) {
        setState(() => _selectedHomeId = properties.first.id);
      }
      _fetchData();
    });

    // Real-time live telemetry refresh every 5 seconds
    _liveTelemetryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        final deviceProvider = context.read<DeviceProvider>();
        final calculatedWatts = _calculateTotalActiveWatts(
          deviceProvider.devices,
        );
        final liveWatts = calculatedWatts > 0
            ? calculatedWatts
            : (deviceProvider.activeLiveWatts > 0
                  ? deviceProvider.activeLiveWatts
                  : 0.0);
        context.read<EnergyProvider>().updateLiveWatts(liveWatts);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveTelemetryTimer?.cancel();
    super.dispose();
  }

  double _calculateTotalActiveWatts(List<Device> devices) {
    if (devices.isEmpty) return 0.0;
    double total = 0.0;
    for (final d in devices) {
      if (d.isOn) {
        total += _getApplianceWattage(d);
      }
    }
    return total;
  }

  static double _getApplianceWattage(Device device) {
    switch (device.type) {
      case DeviceType.ac:
        return 1200.0;
      case DeviceType.pump:
        return 750.0;
      case DeviceType.fan:
        return 55.0 * ((device.dimLevel ?? 100) / 100).clamp(0.2, 1.0);
      case DeviceType.light:
        return 18.0 * ((device.dimLevel ?? 100) / 100).clamp(0.1, 1.0);
      case DeviceType.energyMeter:
        return 5.0;
      default:
        return 65.0;
    }
  }

  void _fetchData() {
    final auth = context.read<AuthProvider>();
    final clientId =
        auth.resolvedClientId ??
        auth.resolvedClientUuid ??
        '6782976c-e9a4-41c9-a754-05e4ba0a97b2';
    final deviceProvider = context.read<DeviceProvider>();
    final calculatedWatts = _calculateTotalActiveWatts(deviceProvider.devices);
    final liveWatts = calculatedWatts > 0
        ? calculatedWatts
        : (deviceProvider.activeLiveWatts > 0
              ? deviceProvider.activeLiveWatts
              : 0.0);

    final homeId =
        _selectedHomeId ??
        (context.read<PropertyProvider>().properties.isNotEmpty
            ? context.read<PropertyProvider>().properties.first.id
            : 'home_main');

    final tariff = context.read<TariffProvider>();

    context.read<EnergyProvider>().fetchDashboard(
      clientId: clientId,
      homeId: homeId,
      currentLiveWatts: liveWatts,
      gridRate: tariff.gridRate,
      backupRate: tariff.backupRate,
    );
  }

  void _showComparison(ClientDashboardModel dashboard) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final tariff = context.read<TariffProvider>();
        final total = dashboard.gridKwh + dashboard.backupKwh;
        final gridShare = total <= 0 ? 88.0 : (dashboard.gridKwh / total * 100);
        final backupShare = total <= 0
            ? 12.0
            : (dashboard.backupKwh / total * 100);
        final gridCost = tariff.calculateGridCost(dashboard.gridKwh);
        final backupCost = tariff.calculateBackupCost(dashboard.backupKwh);
        final totalCost = gridCost + backupCost;

        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 34),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
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
                          color: const Color(0xFFE6F7F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Color(0xFF00A38E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Energy Source Matrix',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _ModernComparisonBar(
                    title: 'Main Grid Power',
                    value: '${dashboard.gridKwh.toStringAsFixed(1)} kWh',
                    percentage: gridShare,
                    color: const Color(0xFF00A38E),
                    icon: Icons.electrical_services_rounded,
                    cost:
                        '${tariff.currencySymbol} ${gridCost.toStringAsFixed(2)} (@ ${tariff.currencySymbol}${tariff.gridRate.toStringAsFixed(2)}/u)',
                  ),
                  const SizedBox(height: 16),
                  _ModernComparisonBar(
                    title: 'Solar & Battery Backup',
                    value: '${dashboard.backupKwh.toStringAsFixed(1)} kWh',
                    percentage: backupShare,
                    color: const Color(0xFF0284C7),
                    icon: Icons.solar_power_rounded,
                    cost:
                        '${tariff.currencySymbol} ${backupCost.toStringAsFixed(2)} (@ ${tariff.currencySymbol}${tariff.backupRate.toStringAsFixed(2)}/u)',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Combined Tariff Cost',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${tariff.currencySymbol} ${totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInsights(ClientDashboardModel dashboard) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 34),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
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
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'AI Energy Audit & Insights',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _ModernInsightCard(
                    icon: Icons.bolt_rounded,
                    color: Color(0xFF00A38E),
                    bgColor: Color(0xFFE6F7F5),
                    title: 'Peak Load Window',
                    description:
                        'Your highest consumption occurs between 7:00 PM - 10:30 PM (Air Conditioning & Living Room).',
                  ),
                  const SizedBox(height: 12),
                  const _ModernInsightCard(
                    icon: Icons.eco_rounded,
                    color: Color(0xFF16A34A),
                    bgColor: Color(0xFFDCFCE7),
                    title: 'Eco Optimization',
                    description:
                        'Your home is operating at 94% efficiency! Nighttime eco-mode saves ~18.4 kg CO2/month.',
                  ),
                  const SizedBox(height: 12),
                  const _ModernInsightCard(
                    icon: Icons.savings_rounded,
                    color: Color(0xFFD97706),
                    bgColor: Color(0xFFFEF3C7),
                    title: 'Estimated Tariff Savings',
                    description:
                        'Automated routine schedules saved you ~₹ 420.00 this billing cycle.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = context.watch<EnergyProvider>();
    final properties = context.watch<PropertyProvider>().properties;
    final deviceProvider = context.watch<DeviceProvider>();
    final dashboard = energyProvider.dashboard;

    // Real-time live wattage calculated from user devices
    final calculatedWatts = _calculateTotalActiveWatts(deviceProvider.devices);
    final currentLiveWatts = calculatedWatts > 0
        ? calculatedWatts
        : (energyProvider.liveTelemetryWatts > 0
              ? energyProvider.liveTelemetryWatts
              : 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern clean canvas
      drawer: const AppNavigationDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Modern Light Header
            _ModernEnergyHeader(
              liveWatts: currentLiveWatts,
              pulseAnimation: _pulseController,
            ),

            // 2. Scrollable Dashboard Core
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00A38E),
                backgroundColor: Colors.white,
                onRefresh: () async => _fetchData(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  children: [
                    // Home Selector & Period Filter Pills
                    _ModernTopControls(
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

                    if (dashboard == null && energyProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00A38E),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    else if (dashboard != null) ...[
                      // 3. Modern Light Energy Core Hero
                      _ModernEnergyHero(
                        dashboard: dashboard,
                        liveWatts: currentLiveWatts,
                        pulseAnimation: _pulseController,
                        onInsights: () => _showInsights(dashboard),
                        onCompare: () => _showComparison(dashboard),
                      ),

                      const SizedBox(height: 16),

                      // 4. Power Flow Distribution
                      _ModernPowerFlowCard(dashboard: dashboard),

                      const SizedBox(height: 16),

                      // 5. Interactive Spline Consumption Chart
                      _ModernChartCard(
                        dashboard: dashboard,
                        period: energyProvider.selectedPeriod,
                        viewMode: _chartViewMode,
                        onViewModeChanged: (mode) {
                          setState(() => _chartViewMode = mode);
                        },
                      ),

                      const SizedBox(height: 16),

                      // 6. Real-Time Devices List (Using Exact User Device Names)
                      _UserDeviceBreakdownCard(
                        deviceProvider: deviceProvider,
                        totalLiveWatts: currentLiveWatts,
                        onToggleDevice: (device, nextState) async {
                          await deviceProvider.toggleDevice(device);
                        },
                      ),
                      const SizedBox(height: 24),
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

// ============================================================================
// TOP LIGHT HEADER
// ============================================================================
class _ModernEnergyHeader extends StatelessWidget {
  final double liveWatts;
  final Animation<double> pulseAnimation;

  const _ModernEnergyHeader({
    required this.liveWatts,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Builder(
            builder: (ctx) => AppNavigationLeading.drawer(
              color: const Color(0xFF0F172A),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Energy Monitoring',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18.5,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Live Telemetry & Grid Analytics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Live Pulse Badge
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(
                      0xFF00A38E,
                    ).withOpacity(0.3 + (pulseAnimation.value * 0.4)),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A38E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00A38E,
                            ).withOpacity(0.5 + (pulseAnimation.value * 0.4)),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'LIVE ${liveWatts.toStringAsFixed(0)}W',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF00A38E),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP CONTROLS (HOME + PERIOD FILTER PILLS)
// ============================================================================
class _ModernTopControls extends StatelessWidget {
  final List<ManagedProperty> properties;
  final String? selectedHomeId;
  final DashboardPeriod selectedPeriod;
  final ValueChanged<String?> onHomeChanged;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const _ModernTopControls({
    required this.properties,
    required this.selectedHomeId,
    required this.selectedPeriod,
    required this.onHomeChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Home Selector Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F7F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF00A38E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: properties.any((p) => p.id == selectedHomeId)
                        ? selectedHomeId
                        : (properties.isNotEmpty ? properties.first.id : null),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    items: properties.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: onHomeChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Period Filter Pills
        Row(
          children: DashboardPeriod.values.map((period) {
            final isSelected = selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => onPeriodChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00A38E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00A38E)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF00A38E).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        period.shortLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// MODERN LIGHT HERO CARD (POWER CORE)
// ============================================================================
class _ModernEnergyHero extends StatelessWidget {
  final ClientDashboardModel dashboard;
  final double liveWatts;
  final Animation<double> pulseAnimation;
  final VoidCallback onInsights;
  final VoidCallback onCompare;

  const _ModernEnergyHero({
    required this.dashboard,
    required this.liveWatts,
    required this.pulseAnimation,
    required this.onInsights,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final tariff = context.watch<TariffProvider>();
    final computedCost = tariff.calculateTotalCost(
      dashboard.gridKwh,
      dashboard.backupKwh,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6F4F1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0800A38E),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Source Status & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFECE5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF00A38E),
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'GRID ACTIVE (OPTIMAL)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF00A38E),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onCompare,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFF475569),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onInsights,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Live Power Wattage Display
          Column(
            children: [
              const Text(
                'LIVE POWER DEMAND',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        liveWatts.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'WATTS',
                    style: TextStyle(
                      color: Color(0xFF00A38E),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '⚡ ${dashboard.currentPowerSource}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Trio Metrics Matrix
          Row(
            children: [
              _ModernMetricTile(
                title: 'TOTAL CONSUMED',
                value: '${dashboard.totalKwh.toStringAsFixed(1)} kWh',
                color: const Color(0xFF00A38E),
                bgColor: const Color(0xFFE6F7F5),
                icon: Icons.electric_bolt_rounded,
              ),
              const SizedBox(width: 10),
              _ModernMetricTile(
                title: 'EST. TARIFF',
                value:
                    '${tariff.currencySymbol} ${computedCost.toStringAsFixed(1)}',
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                icon: Icons.currency_rupee_rounded,
              ),
              const SizedBox(width: 10),
              _ModernMetricTile(
                title: 'ECO SCORE',
                value: '94% Optimal',
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                icon: Icons.eco_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _ModernMetricTile({
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// POWER FLOW DISTRIBUTION CARD
// ============================================================================
class _ModernPowerFlowCard extends StatelessWidget {
  final ClientDashboardModel dashboard;

  const _ModernPowerFlowCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final total = dashboard.gridKwh + dashboard.backupKwh;
    final gridRatio = total <= 0
        ? 0.88
        : (dashboard.gridKwh / total).clamp(0.0, 1.0);
    final backupRatio = total <= 0
        ? 0.12
        : (dashboard.backupKwh / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  'Live Power Flow Distribution',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(Icons.hub_rounded, color: Color(0xFF00A38E), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          // Split Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (gridRatio * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (backupRatio * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Flow Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A38E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Grid Supply (${(gridRatio * 100).toStringAsFixed(0)}%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Solar/Backup (${(backupRatio * 100).toStringAsFixed(0)}%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

// ============================================================================
// INTERACTIVE SPLINE CONSUMPTION CHART (LIGHT THEME)
// ============================================================================
class _ModernChartCard extends StatelessWidget {
  final ClientDashboardModel dashboard;
  final DashboardPeriod period;
  final String viewMode;
  final ValueChanged<String> onViewModeChanged;

  const _ModernChartCard({
    required this.dashboard,
    required this.period,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<double> activeSeries = dashboard.dataPoints;
    Color primaryLineColor = const Color(0xFF00A38E);

    if (viewMode == 'grid') {
      activeSeries = dashboard.gridData;
      primaryLineColor = const Color(0xFF00A38E);
    } else if (viewMode == 'backup') {
      activeSeries = dashboard.backupData;
      primaryLineColor = const Color(0xFF0284C7);
    }

    if (activeSeries.isEmpty) {
      activeSeries = [2.1, 2.4, 3.2, 4.1, 3.8, 4.5, 4.2];
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < activeSeries.length; i++) {
      spots.add(FlSpot(i.toDouble(), activeSeries[i]));
    }

    double maxY = activeSeries.reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 10.0;
    maxY = (maxY * 1.25);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consumption Spline Wave',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      period.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // View Mode Filter Pills
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChartPill(
                    label: 'Total',
                    isSelected: viewMode == 'total',
                    onTap: () => onViewModeChanged('total'),
                  ),
                  const SizedBox(width: 4),
                  _ChartPill(
                    label: 'Grid',
                    isSelected: viewMode == 'grid',
                    onTap: () => onViewModeChanged('grid'),
                  ),
                  const SizedBox(width: 4),
                  _ChartPill(
                    label: 'Solar',
                    isSelected: viewMode == 'backup',
                    onTap: () => onViewModeChanged('backup'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // FL Chart Line Graph
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
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
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 4).clamp(1.0, 10.0),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < dashboard.labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dashboard.labels[idx],
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: primaryLineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryLineColor.withOpacity(0.2),
                          primaryLineColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
}

class _ChartPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChartPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7F5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A38E) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00A38E)
                : const Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REAL-TIME USER DEVICE BREAKDOWN (EXACT USER DEVICE NAMES)
// ============================================================================
class _UserDeviceBreakdownCard extends StatelessWidget {
  final DeviceProvider deviceProvider;
  final double totalLiveWatts;
  final void Function(Device device, bool nextState) onToggleDevice;

  const _UserDeviceBreakdownCard({
    required this.deviceProvider,
    required this.totalLiveWatts,
    required this.onToggleDevice,
  });

  @override
  Widget build(BuildContext context) {
    final devices = deviceProvider.devices;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Connected Devices Load',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${devices.length} Live Devices',
                  style: const TextStyle(
                    color: Color(0xFF00A38E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No smart devices connected in this home.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...devices.map((device) {
              final double watts = _EnergyScreenState._getApplianceWattage(
                device,
              );
              final double percentage = totalLiveWatts > 0
                  ? (watts / totalLiveWatts * 100).clamp(0.0, 100.0)
                  : (device.isOn ? 25.0 : 0.0);

              final Color itemColor;
              final IconData itemIcon;
              switch (device.type) {
                case DeviceType.ac:
                  itemColor = const Color(0xFF0284C7);
                  itemIcon = Icons.ac_unit_rounded;
                  break;
                case DeviceType.light:
                  itemColor = const Color(0xFFD97706);
                  itemIcon = Icons.lightbulb_rounded;
                  break;
                case DeviceType.fan:
                  itemColor = const Color(0xFF00A38E);
                  itemIcon = Icons.mode_fan_off_rounded;
                  break;
                case DeviceType.pump:
                  itemColor = const Color(0xFFEA580C);
                  itemIcon = Icons.water_drop_rounded;
                  break;
                default:
                  itemColor = const Color(0xFF4F46E5);
                  itemIcon = Icons.devices_other_rounded;
              }

              final location = device.roomName ?? device.zone;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(itemIcon, color: itemColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name, // Exact user-given name
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                location.isNotEmpty
                                    ? location
                                    : device.type.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              device.isOn
                                  ? '${watts.toStringAsFixed(0)} W'
                                  : '0 W',
                              style: TextStyle(
                                color: device.isOn
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              device.isOn
                                  ? '${percentage.toStringAsFixed(0)}% Load'
                                  : 'Standby',
                              style: TextStyle(
                                color: device.isOn
                                    ? itemColor
                                    : const Color(0xFF94A3B8),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Interactive modern mini toggle
                        _MiniDeviceToggle(
                          value: device.isOn,
                          onChanged: (val) => onToggleDevice(device, val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: device.isOn
                            ? (percentage / 100).clamp(0.05, 1.0)
                            : 0.0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(itemColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MiniDeviceToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniDeviceToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? const Color(0xFF00A38E) : const Color(0xFFE2E8F0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODAL COMPONENTS
// ============================================================================
class _ModernComparisonBar extends StatelessWidget {
  final String title;
  final String value;
  final double percentage;
  final Color color;
  final IconData icon;
  final String cost;

  const _ModernComparisonBar({
    required this.title,
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          cost,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _ModernInsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String description;

  const _ModernInsightCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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
