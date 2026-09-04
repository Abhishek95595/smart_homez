import 'package:flutter/material.dart';

import '../models/property_hierarchy.dart';
import '../theme/app_theme.dart';

class PropertySummaryCard extends StatelessWidget {
  final ManagedProperty property;
  final int floorCount;
  final int roomCount;
  final int deviceCount;
  final int onlineDeviceCount;
  final VoidCallback onOpen;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PropertySummaryCard({
    super.key,
    required this.property,
    required this.floorCount,
    required this.roomCount,
    required this.deviceCount,
    required this.onlineDeviceCount,
    required this.onOpen,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final allOnline = deviceCount == 0 || onlineDeviceCount == deviceCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCECE8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C00A38E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main property icon gradient card
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2900A38E),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 2,
                            child: Icon(
                              Icons.forest_rounded,
                              size: 28,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${property.category} · ${property.propertyType}',
                            style: const TextStyle(
                              color: Color(0xFF00A38E),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFF00A38E),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  property.address.trim().isEmpty
                                      ? 'Address not added'
                                      : property.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusPill(online: allOnline),
                        _PropertyMenu(
                          onHistory: onHistory,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PropertyStat(
                        value: '$floorCount',
                        label: 'Floors',
                        icon: Icons.layers_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PropertyStat(
                        value: '$roomCount',
                        label: property.isCommercial ? 'Workspaces' : 'Rooms',
                        icon: Icons.sensor_door_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PropertyStat(
                        value: '$deviceCount',
                        label: 'Devices',
                        icon: Icons.devices_other_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCCECE8)),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF00A38E),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyMenu extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyMenu({
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Property actions',
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            return;
          case 'delete':
            onDelete();
            return;
          case 'history':
            onHistory();
            return;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'history',
          child: ListTile(
            leading: Icon(Icons.history_rounded, color: AppColors.primary),
            title: Text('Device history'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool online;

  const _StatusPill({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF059669) : const Color(0xFFD97706);
    final bgColor = online ? const Color(0xFFE6F4EA) : const Color(0xFFFEF3C7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'Online' : 'Offline',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PropertyStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _PropertyStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                child: Icon(icon, size: 15, color: const Color(0xFF00A38E)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
