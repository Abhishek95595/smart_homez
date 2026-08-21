import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/property_provider.dart';
import '../../services/environment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final EnvironmentService _envService = EnvironmentService();
  bool _isLoading = true;
  Map<String, dynamic>? _solarData;
  List<Map<String, dynamic>> _weatherPrompts = [];
  bool _duskDawnEnabled = true;
  String _selectedHomeId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final solar = await _envService.getSolarStatus();
      final duskDawn = await _envService.getDuskDawn();
      final prompts = await _envService.getWeatherPrompts();

      if (mounted) {
        setState(() {
          _solarData = solar;
          _weatherPrompts = prompts;
          if (duskDawn != null && duskDawn.containsKey('enabled')) {
            _duskDawnEnabled = duskDawn['enabled'] == true;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDuskDawn(bool val) async {
    setState(() => _duskDawnEnabled = val);
    await _envService.setDuskDawn({
      'enabled': val,
      'mode': val ? 'automatic' : 'manual',
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;

    if (_selectedHomeId.isEmpty && properties.isNotEmpty) {
      _selectedHomeId = properties.first.id;
    }

    final sunrise = _solarData?['sunrise'] ?? '06:14 AM';
    final sunset = _solarData?['sunset'] ?? '06:48 PM';
    final solarNoon = _solarData?['solarNoon'] ?? '12:31 PM';
    final sunState = _solarData?['sunState'] ?? 'Daylight Optimal';

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Environment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'SOLAR & CLIMATE TELEMETRY',
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0F172A),
            ),
            tooltip: 'Alerts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  children: [
                    // Hero Solar Cycle Card
                    _SolarCycleCard(
                      sunrise: sunrise.toString(),
                      sunset: sunset.toString(),
                      solarNoon: solarNoon.toString(),
                      sunState: sunState.toString(),
                    ),
                    const SizedBox(height: 16),

                    // Dusk to Dawn Automation Tile
                    _DuskToDawnCard(
                      enabled: _duskDawnEnabled,
                      onChanged: _toggleDuskDawn,
                    ),
                    const SizedBox(height: 16),

                    // Climate & Weather Insights
                    const Text(
                      'Environmental Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.thermostat_rounded,
                            label: 'Indoor Temp',
                            value: '23.5 °C',
                            sublabel: 'Comfort Zone',
                            accentColor: Color(0xFF00A38E),
                            badgeColor: Color(0xFFE6F7F5),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Humidity',
                            value: '48 %',
                            sublabel: 'Optimal RH',
                            accentColor: Color(0xFF3B82F6),
                            badgeColor: Color(0xFFEFF6FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.air_rounded,
                            label: 'Air Quality (AQI)',
                            value: '34 PM2.5',
                            sublabel: 'Good • Clean',
                            accentColor: Color(0xFF10B981),
                            badgeColor: Color(0xFFECFDF5),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.wb_sunny_rounded,
                            label: 'UV Index',
                            value: '2.1 Low',
                            sublabel: 'Safe Exposure',
                            accentColor: Color(0xFFF59E0B),
                            badgeColor: Color(0xFFFFFBEB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Smart Weather Prompts
                    if (_weatherPrompts.isNotEmpty) ...[
                      const Text(
                        'Smart Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._weatherPrompts.map(
                        (prompt) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8EEF0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE7F8F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.tips_and_updates_rounded,
                                  color: Color(0xFF00A38E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prompt['title']?.toString() ??
                                          'Climate Automation',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prompt['description']?.toString() ??
                                          'Optimized for natural comfort & energy savings.',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _SolarCycleCard extends StatelessWidget {
  final String sunrise;
  final String sunset;
  final String solarNoon;
  final String sunState;

  const _SolarCycleCard({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.sunState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23C9B5), Color(0xFF00A38E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2200A38E),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solar Cycle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Astronomical Solar Tracking',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  sunState,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SolarTimeItem(
                  icon: Icons.wb_twilight_rounded,
                  label: 'Sunrise',
                  time: sunrise,
                ),
                _SolarTimeItem(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Solar Noon',
                  time: solarNoon,
                ),
                _SolarTimeItem(
                  icon: Icons.nightlight_round,
                  label: 'Sunset',
                  time: sunset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SolarTimeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _SolarTimeItem({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DuskToDawnCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _DuskToDawnCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bedtime_outlined,
              color: Color(0xFF00A38E),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dusk-to-Dawn Automation',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Auto-activate ambient night lights at sunset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00A38E),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;
  final Color badgeColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.accentColor,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
