import 'package:flutter/material.dart';

import '../../services/environment_service.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../alerts/alerts_screen.dart';
import 'environment_theme.dart';
import 'widgets/dusk_to_dawn_card.dart';
import 'widgets/family_presence_card.dart';
import 'widgets/home_location_card.dart';
import 'widgets/live_conditions_grid.dart';
import 'widgets/solar_cycle_hero.dart';
import 'widgets/weather_prompt_card.dart';
import 'widgets/widget_shortcuts_row.dart';

class EnvironmentScreen extends StatefulWidget {
  final EnvironmentService? service;

  const EnvironmentScreen({super.key, this.service});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
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

  @override
  void initState() {
    super.initState();
    _envService = widget.service ?? EnvironmentService();
    _loadAllData();
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
    final previousEnabled = _duskDawnEnabled;
    final previousMode = _duskDawnMode;

    setState(() {
      _duskDawnEnabled = val;
      _duskDawnMode = val ? 'automatic' : 'manual';
    });

    try {
      final success = await _envService.setDuskDawn({
        'enabled': val,
        'mode': val ? 'automatic' : 'manual',
      });
      if (!success && mounted) {
        setState(() {
          _duskDawnEnabled = previousEnabled;
          _duskDawnMode = previousMode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update Dusk-to-Dawn setting.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _duskDawnEnabled = previousEnabled;
          _duskDawnMode = previousMode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating Dusk-to-Dawn setting.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    final sunrise = _solarData?['sunrise']?.toString();
    final sunset = _solarData?['sunset']?.toString();
    final solarNoon = _solarData?['solarNoon']?.toString();
    final sunState = _solarData?['sunState']?.toString();
    final dayLength = _solarData?['dayLength']?.toString();

    // Weather metrics (nullable for safe unavailable representation)
    final temp = _solarData?['temperature']?.toString();
    final humidity = _solarData?['humidity']?.toString();
    final aqi = _solarData?['aqi']?.toString();
    final uvIndex = _solarData?['uvIndex']?.toString();

    final String displayHeaderSunState = sunState != null && sunState.isNotEmpty
        ? sunState
        : 'Unavailable';

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: colors.accent,
          backgroundColor: colors.panel,
          child: Column(
            children: [
              // ─── HASOMI LIGHT HEADER ───
              _buildHeader(context, colors, displayHeaderSunState),

              // ─── BODY CONTENT ───
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: colors.accent),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        children: [
                          // 1. Solar Cycle Hero Card
                          SolarCycleHeroCard(
                            sunrise: sunrise,
                            sunset: sunset,
                            solarNoon: solarNoon,
                            sunState: sunState,
                            dayLength: dayLength,
                          ),
                          const SizedBox(height: 20),

                          // 2. Live Conditions (2x2 Grid)
                          LiveConditionsGrid(
                            temperature: temp,
                            humidity: humidity,
                            aqi: aqi,
                            uvIndex: uvIndex,
                          ),
                          const SizedBox(height: 20),

                          // 3. Dusk-to-Dawn Automation Card
                          DuskToDawnCard(
                            enabled: _duskDawnEnabled,
                            mode: _duskDawnMode,
                            onChanged: _toggleDuskDawn,
                          ),
                          const SizedBox(height: 20),

                          // 4. Family Presence Card
                          FamilyPresenceCard(data: _presenceData),
                          const SizedBox(height: 20),

                          // 5. Home Location Card
                          HomeLocationCard(data: _locationData),
                          const SizedBox(height: 20),

                          // 6. Smart Recommendations (Rendered only when API returns prompts)
                          if (_weatherPrompts.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colors.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: colors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Smart Recommendations',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._weatherPrompts.map(
                              (prompt) => WeatherPromptCard(prompt: prompt),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 7. Quick Shortcuts (Rendered only when API returns widgets)
                          if (_widgetScenes.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colors.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.widgets_rounded,
                                    color: colors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Quick Shortcuts',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            WidgetShortcutsRow(scenes: _widgetScenes),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EnvironmentThemeData colors,
    String sunState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => _HeaderIconButton(
              icon: Icons.menu_rounded,
              colors: colors,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Smart Environment',
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sunState.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            colors: colors,
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            colors: colors,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
            tooltip: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final EnvironmentThemeData colors;
  final VoidCallback onPressed;
  final String? tooltip;

  const _HeaderIconButton({
    required this.icon,
    required this.colors,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(EnvironmentTheme.smallRadius),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(EnvironmentTheme.smallRadius),
            border: Border.all(color: colors.border, width: 1.0),
          ),
          child: Icon(icon, color: colors.textPrimary, size: 20),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
