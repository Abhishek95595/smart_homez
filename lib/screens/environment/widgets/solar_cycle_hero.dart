import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Solar Cycle Hero Card using Hasomi Light Theme design tokens.
/// Safely renders neutral unavailable representations when solar times are missing.
class SolarCycleHeroCard extends StatelessWidget {
  final String? sunrise;
  final String? sunset;
  final String? solarNoon;
  final String? sunState;
  final String? dayLength;

  const SolarCycleHeroCard({
    super.key,
    this.sunrise,
    this.sunset,
    this.solarNoon,
    this.sunState,
    this.dayLength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    final displaySunrise = sunrise != null && sunrise!.isNotEmpty
        ? sunrise!
        : '--:--';
    final displaySunset = sunset != null && sunset!.isNotEmpty
        ? sunset!
        : '--:--';
    final displaySolarNoon = solarNoon != null && solarNoon!.isNotEmpty
        ? solarNoon!
        : '--:--';
    final displaySunState = sunState != null && sunState!.isNotEmpty
        ? sunState!
        : 'Unavailable';
    final displayDayLength = dayLength != null && dayLength!.isNotEmpty
        ? dayLength!
        : '--';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(EnvironmentTheme.largeRadius),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(
                    EnvironmentTheme.smallRadius,
                  ),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  color: colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solar Cycle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day Length: $displayDayLength',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
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
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  displaySunState,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Solar Arc Path Visualization
          SizedBox(
            height: 95,
            child: CustomPaint(
              size: const Size(double.infinity, 95),
              painter: _SolarArcPainter(
                arcColor: colors.accent,
                trackColor: colors.border,
              ),
              child: Align(
                alignment: const Alignment(0, 0.65),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _ArcTimeLabel(
                        icon: Icons.wb_twilight_rounded,
                        label: 'Sunrise',
                        time: displaySunrise,
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: colors.accent,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              displaySolarNoon,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Solar Noon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ArcTimeLabel(
                        icon: Icons.nightlight_round,
                        label: 'Sunset',
                        time: displaySunset,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcTimeLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final EnvironmentThemeData colors;

  const _ArcTimeLabel({
    required this.icon,
    required this.label,
    required this.time,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.accent, size: 17),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SolarArcPainter extends CustomPainter {
  final Color arcColor;
  final Color trackColor;

  _SolarArcPainter({required this.arcColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(20, 10, size.width - 40, size.height * 1.4);
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi * 0.65, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SolarArcPainter oldDelegate) {
    return oldDelegate.arcColor != arcColor ||
        oldDelegate.trackColor != trackColor;
  }
}
