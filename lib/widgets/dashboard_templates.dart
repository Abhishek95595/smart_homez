import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardLayoutWrapper extends StatelessWidget {
  final Widget child;
  const DashboardLayoutWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [child],
    );
  }
}

class DashboardStatGrid extends StatelessWidget {
  final List<Widget> children;
  const DashboardStatGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map(
            (c) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: c == children.last ? 0 : 12),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }
}

class CommercialStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const CommercialStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sideBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: themeColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.sideTextDim,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
