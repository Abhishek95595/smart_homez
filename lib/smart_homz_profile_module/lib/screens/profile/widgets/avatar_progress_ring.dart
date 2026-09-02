import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../providers/profile_provider.dart';
import '../profile_theme.dart';

/// Animated circular progress ring showing the online devices ratio around the user's avatar,
/// styled with a subtle ambient glow and a mint/teal edit badge.
class AvatarProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final AvatarOption avatar;
  final String fallbackInitials;
  final VoidCallback onEdit;

  const AvatarProgressRing({
    super.key,
    required this.progress,
    required this.avatar,
    required this.fallbackInitials,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ProfileTheme.of(context);
    const double size = 112.0;
    const double strokeWidth = 3.5;
    const double avatarSize = 92.0;

    final Color trackColor = colors.isDark
        ? const Color(0x12FFFFFF)
        : const Color(0xFFE2EAE8);
    final Color editIconColor = colors.isDark
        ? colors.background
        : Colors.white;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Subtle ambient glow behind avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(
                    alpha: colors.isDark ? 0.12 : 0.08,
                  ),
                  blurRadius: colors.isDark ? 24 : 18,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),

          // Animated Progress Ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return CustomPaint(
                size: const Size(size, size),
                painter: _RingPainter(
                  progress: animatedValue,
                  strokeWidth: strokeWidth,
                  trackColor: trackColor,
                  progressColor: colors.accent,
                ),
              );
            },
          ),

          // Avatar Image or Fallback Initials
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.raised,
                border: Border.all(color: colors.background, width: 3.0),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatar.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colors.panel,
                      alignment: Alignment.center,
                      child: Text(
                        fallbackInitials.isNotEmpty ? fallbackInitials : 'SH',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Circular Mint Edit Badge Button
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, color: editIconColor, size: 14),
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
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Progress arc starting from top (-90 degrees)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
