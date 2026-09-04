import 'package:flutter/material.dart';

import '../models/robot_avatar.dart';

/// Reusable widget for rendering Smart Homz HASOMI robot avatars cleanly and responsively.
///
/// Features:
/// - Enforces a 1:1 square aspect ratio with [BoxFit.contain].
/// - Uses [AnimatedSwitcher] with [ValueKey] for smooth state transitions (250ms).
/// - Optional container background, border, padding, and tap handler.
/// - Full accessibility [Semantics] support.
class RobotAvatar extends StatelessWidget {
  final RobotAvatarType type;
  final double size;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  final bool useContainer;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const RobotAvatar({
    super.key,
    required this.type,
    this.size = 120.0,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.useContainer = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  });

  /// Factory constructor for a compact avatar (e.g. 40px)
  const RobotAvatar.small({
    super.key,
    required this.type,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.useContainer = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  }) : size = 40.0;

  /// Factory constructor for a medium avatar (e.g. 80px)
  const RobotAvatar.medium({
    super.key,
    required this.type,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.useContainer = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  }) : size = 80.0;

  /// Factory constructor for a large hero avatar (e.g. 150px)
  const RobotAvatar.large({
    super.key,
    required this.type,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.useContainer = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  }) : size = 150.0;

  @override
  Widget build(BuildContext context) {
    final String label = semanticLabel ?? type.semanticLabel;

    Widget avatarWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: AspectRatio(
        key: ValueKey<RobotAvatarType>(type),
        aspectRatio: 1.0,
        child: Image.asset(
          type.assetPath,
          fit: fit,
          alignment: alignment,
          semanticLabel: label,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.teal.withValues(alpha: 0.1),
              alignment: Alignment.center,
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.teal,
                size: 32,
              ),
            );
          },
        ),
      ),
    );

    if (useContainer ||
        backgroundColor != null ||
        borderColor != null ||
        padding != null) {
      avatarWidget = Container(
        padding: padding ?? EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: avatarWidget,
      );
    }

    Widget content = Semantics(
      label: label,
      image: true,
      child: SizedBox(width: size, height: size, child: avatarWidget),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
