import 'package:flutter/material.dart';

enum AppNavigationLeadingType { drawer, back }

/// Standard leading button widget for Smart Homz screens.
///
/// - Use [AppNavigationLeading.drawer] (`☰`) for top-level drawer destinations.
/// - Use [AppNavigationLeading.back] (`←`) for inner child/detail/create/edit screens.
class AppNavigationLeading extends StatelessWidget {
  final AppNavigationLeadingType type;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;

  const AppNavigationLeading.drawer({
    super.key,
    this.onPressed,
    this.color,
    this.tooltip = 'Navigation Menu',
  }) : type = AppNavigationLeadingType.drawer;

  const AppNavigationLeading.back({
    super.key,
    this.onPressed,
    this.color,
    this.tooltip = 'Back',
  }) : type = AppNavigationLeadingType.back;

  @override
  Widget build(BuildContext context) {
    if (type == AppNavigationLeadingType.drawer) {
      return IconButton(
        tooltip: tooltip,
        icon: Icon(Icons.menu_rounded, size: 28, color: color),
        onPressed:
            onPressed ??
            () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              }
            },
      );
    }

    return IconButton(
      tooltip: tooltip,
      icon: Icon(Icons.arrow_back_rounded, size: 24, color: color),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
