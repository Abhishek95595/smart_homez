import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/environment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';

class EnvironmentScreen extends StatefulWidget {
  final EnvironmentService? service;

  const EnvironmentScreen({super.key, this.service});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen>
    with TickerProviderStateMixin {
  late final EnvironmentService _envService;
  bool _isLoading = true;

  // API Data
  Map<String, dynamic>? _solarData;
  List<Map<String, dynamic>> _weatherPrompts = [];
  bool _duskDawnEnabled = true;
  String _duskDawnMode = 'automatic';
  Map<String, dynamic>? _presenceData;
  Map<String, dynamic>? _locationData;
  List<Map<String, dynamic>> _widgetScenes = [];

  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _envService = widget.service ?? EnvironmentService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadAllData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _envService.getSolarStatus(), // 0
        _envService.getDuskDawn(), // 1
        _envService.getWeatherPrompts(), // 2
        _envService.getPresence(), // 3
        _envService.getHomeLocation(), // 4
        _envService.getWidgets(), // 5
      ]);

      if (mounted) {
        setState(() {
          _solarData = results[0] as Map<String, dynamic>?;

          final duskDawn = results[1] as Map<String, dynamic>?;
          if (duskDawn != null) {
            _duskDawnEnabled = duskDawn['enabled'] == true;
            _duskDawnMode = duskDawn['mode']?.toString() ?? 'automatic';
          }

          _weatherPrompts =
              (results[2] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          _presenceData = results[3] as Map<String, dynamic>?;
          _locationData = results[4] as Map<String, dynamic>?;
          _widgetScenes =
              (results[5] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDuskDawn(bool val) async {
    setState(() {
      _duskDawnEnabled = val;
      _duskDawnMode = val ? 'automatic' : 'manual';
    });
    await _envService.setDuskDawn({
      'enabled': val,
      'mode': val ? 'automatic' : 'manual',
    });
  }

  @override
  Widget build(BuildContext context) {
    final sunrise = _solarData?['sunrise']?.toString() ?? '06:14 AM';
    final sunset = _solarData?['sunset']?.toString() ?? '06:48 PM';
    final solarNoon = _solarData?['solarNoon']?.toString() ?? '12:31 PM';
    final sunState = _solarData?['sunState']?.toString() ?? 'Daylight';
    final dayLength = _solarData?['dayLength']?.toString() ?? '12h 34m';

    // Extract weather metrics from solar/weather data
    final temp = _solarData?['temperature']?.toString() ?? '24.5';
    final humidity = _solarData?['humidity']?.toString() ?? '52';
    final aqi = _solarData?['aqi']?.toString() ?? '38';
    final uvIndex = _solarData?['uvIndex']?.toString() ?? '2.4';

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: const Color(0xFFF0F5F4),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ─── CUSTOM SLIVER APP BAR ───
              _buildSliverAppBar(sunState),

              // ─── BODY CONTENT ───
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Solar Arc Hero Card
                          _SolarArcHero(
                            sunrise: sunrise,
                            sunset: sunset,
                            solarNoon: solarNoon,
                            sunState: sunState,
                            dayLength: dayLength,
                            pulseAnimation: _pulseController,
                          ),
                          const SizedBox(height: 20),

                          // 2. Environment Metrics Grid
                          _buildSectionTitle(
                            'Live Conditions',
                            Icons.sensors_rounded,
                          ),
                          const SizedBox(height: 12),
                          _EnvironmentMetricsGrid(
                            temperature: temp,
                            humidity: humidity,
                            aqi: aqi,
                            uvIndex: uvIndex,
                          ),
                          const SizedBox(height: 24),

                          // 3. Dusk-to-Dawn Automation
                          _DuskDawnPremiumCard(
                            enabled: _duskDawnEnabled,
                            mode: _duskDawnMode,
                            onChanged: _toggleDuskDawn,
                          ),
                          const SizedBox(height: 24),

                          // 4. Family Presence
                          _buildSectionTitle(
                            'Family Presence',
                            Icons.people_alt_rounded,
                          ),
                          const SizedBox(height: 12),
                          _PresenceCard(data: _presenceData),
                          const SizedBox(height: 24),

                          // 5. Home Location
                          _buildSectionTitle(
                            'Home Location',
                            Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 12),
                          _HomeLocationCard(data: _locationData),
                          const SizedBox(height: 24),

                          // 6. Smart Recommendations
                          if (_weatherPrompts.isNotEmpty) ...[
                            _buildSectionTitle(
                              'Smart Recommendations',
                              Icons.auto_awesome_rounded,
                            ),
                            const SizedBox(height: 12),
                            ..._weatherPrompts.map(
                              (prompt) => _WeatherPromptCard(prompt: prompt),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 7. Widget Shortcuts
                          if (_widgetScenes.isNotEmpty) ...[
                            _buildSectionTitle(
                              'Quick Shortcuts',
                              Icons.widgets_rounded,
                            ),
                            const SizedBox(height: 12),
                            _WidgetShortcutsRow(scenes: _widgetScenes),
                          ],
                        ]),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String sunState) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A2E2A),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          tooltip: 'Refresh',
          onPressed: _loadAllData,
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white70,
          ),
          tooltip: 'Alerts',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2E2A), Color(0xFF134E46)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Subtle decorative circles
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Environment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              sunState.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5EEAD4).withValues(alpha: 0.9),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. SOLAR ARC HERO
// ═══════════════════════════════════════════════════════════════

class _SolarArcHero extends StatelessWidget {
  final String sunrise, sunset, solarNoon, sunState, dayLength;
  final AnimationController pulseAnimation;

  const _SolarArcHero({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.sunState,
    required this.dayLength,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF134E46), Color(0xFF0A7E6E), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative orbs
            Positioned(
              right: -20,
              top: -20,
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (_, _) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: 0.04 + (pulseAnimation.value * 0.03),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  // Title row
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: pulseAnimation,
                        builder: (_, _) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBBF24).withValues(
                                  alpha: 0.1 + (pulseAnimation.value * 0.15),
                                ),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: Color(0xFFFBBF24),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solar Cycle',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Day Length: $dayLength',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
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
                  const SizedBox(height: 22),

                  // Solar Arc Visualization
                  SizedBox(
                    height: 90,
                    child: CustomPaint(
                      size: const Size(double.infinity, 90),
                      painter: _SolarArcPainter(),
                      child: Align(
                        alignment: const Alignment(0, 0.6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _ArcTimeLabel(
                              icon: Icons.wb_twilight_rounded,
                              label: 'Sunrise',
                              time: sunrise,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Color(0xFFFBBF24),
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  solarNoon,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Solar Noon',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            _ArcTimeLabel(
                              icon: Icons.nightlight_round,
                              label: 'Sunset',
                              time: sunset,
                            ),
                          ],
                        ),
                      ),
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

class _ArcTimeLabel extends StatelessWidget {
  final IconData icon;
  final String label, time;

  const _ArcTimeLabel({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFBBF24), size: 16),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SolarArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(20, 10, size.width - 40, size.height * 1.4);
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    // Gradient overlay arc
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFEF4444)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi * 0.6, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// 2. ENVIRONMENT METRICS GRID
// ═══════════════════════════════════════════════════════════════

class _EnvironmentMetricsGrid extends StatelessWidget {
  final String temperature, humidity, aqi, uvIndex;

  const _EnvironmentMetricsGrid({
    required this.temperature,
    required this.humidity,
    required this.aqi,
    required this.uvIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassMetricCard(
                icon: Icons.thermostat_rounded,
                label: 'Temperature',
                value: '$temperature°',
                unit: 'C',
                sublabel: _tempLabel(temperature),
                progress: _clamp01(double.tryParse(temperature) ?? 24, 0, 50),
                ringColor: const Color(0xFF10B981),
                bgGradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassMetricCard(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '$humidity%',
                unit: 'RH',
                sublabel: _humidityLabel(humidity),
                progress: _clamp01(double.tryParse(humidity) ?? 50, 0, 100),
                ringColor: const Color(0xFF3B82F6),
                bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassMetricCard(
                icon: Icons.air_rounded,
                label: 'Air Quality',
                value: aqi,
                unit: 'AQI',
                sublabel: _aqiLabel(aqi),
                progress: _clamp01(double.tryParse(aqi) ?? 38, 0, 300),
                ringColor: const Color(0xFF10B981),
                bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassMetricCard(
                icon: Icons.wb_sunny_rounded,
                label: 'UV Index',
                value: uvIndex,
                unit: 'UV',
                sublabel: _uvLabel(uvIndex),
                progress: _clamp01(double.tryParse(uvIndex) ?? 2.4, 0, 11),
                ringColor: const Color(0xFFF59E0B),
                bgGradient: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static double _clamp01(double val, double min, double max) =>
      ((val - min) / (max - min)).clamp(0.0, 1.0);

  static String _tempLabel(String t) {
    final v = double.tryParse(t) ?? 24;
    if (v < 18) return 'Cool';
    if (v < 26) return 'Comfort Zone';
    if (v < 32) return 'Warm';
    return 'Hot';
  }

  static String _humidityLabel(String h) {
    final v = double.tryParse(h) ?? 50;
    if (v < 30) return 'Dry';
    if (v < 60) return 'Optimal';
    return 'Humid';
  }

  static String _aqiLabel(String a) {
    final v = double.tryParse(a) ?? 38;
    if (v <= 50) return 'Good';
    if (v <= 100) return 'Moderate';
    if (v <= 150) return 'Unhealthy (Sensitive)';
    return 'Unhealthy';
  }

  static String _uvLabel(String u) {
    final v = double.tryParse(u) ?? 2.4;
    if (v < 3) return 'Low Risk';
    if (v < 6) return 'Moderate';
    if (v < 8) return 'High';
    return 'Very High';
  }
}

class _GlassMetricCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit, sublabel;
  final double progress;
  final Color ringColor;
  final List<Color> bgGradient;

  const _GlassMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.sublabel,
    required this.progress,
    required this.ringColor,
    required this.bgGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ringColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.08),
            blurRadius: 16,
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
                  color: ringColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ringColor, size: 19),
              ),
              // Mini ring progress
              SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _RingPainter(progress: progress, color: ringColor),
                  child: Center(
                    child: Text(
                      '${(progress * 100).round()}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: ringColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: ringColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ringColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ringColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ringColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════
// 3. DUSK-TO-DAWN PREMIUM CARD
// ═══════════════════════════════════════════════════════════════

class _DuskDawnPremiumCard extends StatelessWidget {
  final bool enabled;
  final String mode;
  final ValueChanged<bool> onChanged;

  const _DuskDawnPremiumCard({
    required this.enabled,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: enabled ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          else
            const BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                  : null,
              color: enabled ? null : const Color(0xFFF1F5F9),
            ),
            child: Icon(
              enabled ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              color: enabled ? Colors.white : const Color(0xFF94A3B8),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dusk-to-Dawn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: enabled ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? 'Night lights activate at sunset'
                      : 'Manual lighting mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFA78BFA),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF8B5CF6),
            activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. FAMILY PRESENCE CARD
// ═══════════════════════════════════════════════════════════════

class _PresenceCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _PresenceCard({this.data});

  @override
  Widget build(BuildContext context) {
    final homeState = data?['homeState']?.toString() ?? 'unknown';
    final members = data?['members'] as List<dynamic>? ?? [];
    final homeCount = members.where((m) {
      final s = m is Map ? m['status']?.toString() : null;
      return s == 'home' || s == 'present';
    }).length;

    final isOccupied =
        homeState == 'occupied' || homeState == 'home' || homeCount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOccupied
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOccupied ? Icons.home_rounded : Icons.home_outlined,
                  color: isOccupied
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOccupied ? 'Home Occupied' : 'Home Empty',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$homeCount member${homeCount == 1 ? '' : 's'} at home',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isOccupied
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOccupied
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOccupied ? 'ACTIVE' : 'AWAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isOccupied
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (members.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 14),

            // Member list
            ...members.map((m) {
              if (m is! Map) return const SizedBox.shrink();
              final name = m['name']?.toString() ?? 'Member';
              final status = m['status']?.toString() ?? 'unknown';
              final isHome = status == 'home' || status == 'present';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isHome
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                              ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHome
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHome ? 'Home' : 'Away',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isHome
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                'No presence data available yet',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. HOME LOCATION CARD
// ═══════════════════════════════════════════════════════════════

class _HomeLocationCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _HomeLocationCard({this.data});

  @override
  Widget build(BuildContext context) {
    final lat = data?['latitude']?.toString() ?? '--';
    final lng = data?['longitude']?.toString() ?? '--';
    final geofenceRadius = data?['geofenceRadius']?.toString() ?? '100';
    final ssid = data?['wifiSsid']?.toString() ?? data?['ssid']?.toString();
    final address = data?['address']?.toString();
    final hasData = data != null && lat != '--';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map-style header
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE0F2FE),
                  Color(0xFFBAE6FD),
                  Color(0xFF7DD3FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Grid lines for map feel
                ...List.generate(
                  4,
                  (i) => Positioned(
                    left: 0,
                    right: 0,
                    top: (i + 1) * 16.0,
                    child: Container(
                      height: 0.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                ...List.generate(
                  6,
                  (i) => Positioned(
                    top: 0,
                    bottom: 0,
                    left: (i + 1) * 50.0,
                    child: Container(
                      width: 0.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                // Center pin
                const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                // Geofence ring
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (address != null && address.isNotEmpty) ...[
            Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Coordinates
          Row(
            children: [
              _LocationChip(
                icon: Icons.my_location_rounded,
                label: hasData ? '$lat, $lng' : 'Not configured',
              ),
              if (hasData) ...[
                const SizedBox(width: 8),
                _LocationChip(
                  icon: Icons.radar_rounded,
                  label: '${geofenceRadius}m',
                ),
              ],
            ],
          ),

          if (ssid != null && ssid.isNotEmpty) ...[
            const SizedBox(height: 8),
            _LocationChip(icon: Icons.wifi_rounded, label: ssid),
          ],
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LocationChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 6. WEATHER PROMPT CARD
// ═══════════════════════════════════════════════════════════════

class _WeatherPromptCard extends StatelessWidget {
  final Map<String, dynamic> prompt;

  const _WeatherPromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final title = prompt['title']?.toString() ?? 'Climate Tip';
    final desc =
        prompt['description']?.toString() ??
        'Optimized for natural comfort & savings.';
    final type = prompt['type']?.toString() ?? '';

    IconData icon;
    Color accent;
    switch (type.toLowerCase()) {
      case 'rain':
      case 'humidity':
        icon = Icons.water_drop_rounded;
        accent = const Color(0xFF3B82F6);
        break;
      case 'heat':
      case 'temperature':
        icon = Icons.thermostat_rounded;
        accent = const Color(0xFFEF4444);
        break;
      case 'wind':
        icon = Icons.air_rounded;
        accent = const Color(0xFF06B6D4);
        break;
      case 'uv':
      case 'sun':
        icon = Icons.wb_sunny_rounded;
        accent = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.tips_and_updates_rounded;
        accent = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: accent.withValues(alpha: 0.4),
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 7. WIDGET SHORTCUTS ROW
// ═══════════════════════════════════════════════════════════════

class _WidgetShortcutsRow extends StatelessWidget {
  final List<Map<String, dynamic>> scenes;

  const _WidgetShortcutsRow({required this.scenes});

  static const List<Color> _palette = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  static const List<IconData> _icons = [
    Icons.lightbulb_outline_rounded,
    Icons.thermostat_rounded,
    Icons.nightlight_round,
    Icons.movie_outlined,
    Icons.lock_outline_rounded,
    Icons.power_settings_new_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: scenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          final name = scene['name']?.toString() ?? 'Scene';
          final color = _palette[index % _palette.length];
          final icon = _icons[index % _icons.length];

          return Container(
            width: 90,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
