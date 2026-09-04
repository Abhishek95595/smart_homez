import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../environment_theme.dart';

/// Section showing 2x2 grid of Live Environment Conditions (Temperature, Humidity, Air Quality, UV Index).
/// Renders neutral unavailable states when sensor readings are missing.
class LiveConditionsGrid extends StatelessWidget {
  final String? temperature;
  final String? humidity;
  final String? aqi;
  final String? uvIndex;

  const LiveConditionsGrid({
    super.key,
    this.temperature,
    this.humidity,
    this.aqi,
    this.uvIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = EnvironmentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.sensors_rounded,
                color: colors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Live Conditions',
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
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.thermostat_rounded,
                label: 'Temperature',
                value: temperature != null && temperature!.isNotEmpty
                    ? '$temperature°C'
                    : '--',
                sublabel: _tempLabel(temperature),
                progress: _clamp01(temperature, 0, 50),
                cardBg: colors.tempCardBg,
                accentColor: colors.tempAccent,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: humidity != null && humidity!.isNotEmpty
                    ? '$humidity% RH'
                    : '--',
                sublabel: _humidityLabel(humidity),
                progress: _clamp01(humidity, 0, 100),
                cardBg: colors.humidityCardBg,
                accentColor: colors.humidityAccent,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.air_rounded,
                label: 'Air Quality',
                value: aqi != null && aqi!.isNotEmpty ? '$aqi AQI' : '--',
                sublabel: _aqiLabel(aqi),
                progress: _clamp01(aqi, 0, 300),
                cardBg: colors.aqiCardBg,
                accentColor: colors.aqiAccent,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.wb_sunny_rounded,
                label: 'UV Index',
                value: uvIndex != null && uvIndex!.isNotEmpty
                    ? '$uvIndex UV'
                    : '--',
                sublabel: _uvLabel(uvIndex),
                progress: _clamp01(uvIndex, 0, 11),
                cardBg: colors.uvCardBg,
                accentColor: colors.uvAccent,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static double _clamp01(String? valStr, double min, double max) {
    if (valStr == null || valStr.isEmpty) return 0.0;
    final val = double.tryParse(valStr);
    if (val == null) return 0.0;
    return ((val - min) / (max - min)).clamp(0.0, 1.0);
  }

  static String _tempLabel(String? t) {
    if (t == null || t.isEmpty) return 'Unavailable';
    final v = double.tryParse(t);
    if (v == null) return 'Unavailable';
    if (v < 18) return 'Cool';
    if (v < 26) return 'Comfort Zone';
    if (v < 32) return 'Warm';
    return 'Hot';
  }

  static String _humidityLabel(String? h) {
    if (h == null || h.isEmpty) return 'Unavailable';
    final v = double.tryParse(h);
    if (v == null) return 'Unavailable';
    if (v < 30) return 'Dry';
    if (v < 60) return 'Optimal';
    return 'Humid';
  }

  static String _aqiLabel(String? a) {
    if (a == null || a.isEmpty) return 'Unavailable';
    final v = double.tryParse(a);
    if (v == null) return 'Unavailable';
    if (v <= 50) return 'Good';
    if (v <= 100) return 'Moderate';
    if (v <= 150) return 'Unhealthy (Sensitive)';
    return 'Unhealthy';
  }

  static String _uvLabel(String? u) {
    if (u == null || u.isEmpty) return 'Unavailable';
    final v = double.tryParse(u);
    if (v == null) return 'Unavailable';
    if (v < 3) return 'Low Risk';
    if (v < 6) return 'Moderate';
    if (v < 8) return 'High';
    return 'Very High';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final double progress;
  final Color cardBg;
  final Color accentColor;
  final EnvironmentThemeData colors;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.progress,
    required this.cardBg,
    required this.accentColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = progress > 0.0;
    final effectiveAccent = isAvailable ? accentColor : colors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(EnvironmentTheme.largeRadius),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon on left, Progress ring on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    EnvironmentTheme.smallRadius,
                  ),
                ),
                child: Icon(icon, color: effectiveAccent, size: 19),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(
                  painter: _CircularMetricIndicator(
                    progress: progress,
                    color: effectiveAccent,
                    trackColor: effectiveAccent.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      isAvailable ? '${(progress * 100).round()}' : '--',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: effectiveAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Middle: Metric name & Large value
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bottom: Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: effectiveAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: effectiveAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularMetricIndicator extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CircularMetricIndicator({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (progress > 0.0) {
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
  }

  @override
  bool shouldRepaint(_CircularMetricIndicator old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
