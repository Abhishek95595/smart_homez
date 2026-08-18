import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../models/property_hierarchy.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/property_provider.dart';
import '../alerts/alerts_screen.dart';
import '../automations/automations_screen.dart';
import '../energy/energy_screen.dart';
import '../properties/floors_screen.dart';
import '../properties/homes_screen.dart';
import '../scenes/routine_scene_screen.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeSceneIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final propertyProvider = context.watch<PropertyProvider>();
    final energyProvider = context.watch<EnergyProvider>();
    final userName = user?.name.split(' ').first ?? 'Ayesha';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        centerTitle: true,
        leading: Builder(
          builder: (_) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF0F172A),
              size: 28,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Smart Homez',
          style: TextStyle(
            color: Color(0xFF00A38E),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0F172A),
                    size: 28,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  ),
                ),
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C9A7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          children: [
            // 1. Robot Room Hero Banner
            _HeroGreetingBanner(greeting: _getGreeting(), userName: userName),
            const SizedBox(height: 24),

            // 2. Quick Scenes Section
            _SectionHeader(
              title: 'Quick Scenes',
              actionLabel: 'View All',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutomationsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _QuickScenesRow(
              selectedIndex: _activeSceneIndex,
              onSelect: (index, sceneName) {
                setState(() => _activeSceneIndex = index);

                final routineKeys = [
                  'good_morning',
                  'good_night',
                  'movie_time',
                  'away_mode',
                ];
                final routineKey = routineKeys[index.clamp(0, 3)];
                final themeData = kAllRoutineThemes[routineKey]!;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutineSceneScreen(themeData: themeData),
                  ),
                );
              },
            ),
            const SizedBox(height: 26),

            // 3. Your Properties Section with Overall Energy Matrix Card
            _SectionHeader(
              title: 'Your Properties',
              actionLabel: 'View All',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomesScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _PropertiesAndEnergySection(
              properties: propertyProvider.properties,
              energyProvider: energyProvider,
            ),
            const SizedBox(height: 20),

            // 4. Smart Assistant Floating Voice Banner
            _SmartAssistantVoiceBanner(
              userName: userName,
              onTap: () => _showVoiceAssistantModal(context, userName),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceAssistantModal(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VoiceAssistantModal(userName: userName),
    );
  }
}

class _HeroGreetingBanner extends StatelessWidget {
  final String greeting;
  final String userName;

  const _HeroGreetingBanner({required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 370;

    return Container(
      width: double.infinity,
      height: compact ? 205 : 218,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9F0F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F766E),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_hero_reference.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/home_hero_banner.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            // The reference artwork is intentionally clean on the left so the
            // live greeting and authenticated user's name remain dynamic.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.48),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.44, 0.54],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 20 : 24,
              top: compact ? 20 : 24,
              child: SizedBox(
                width: screenWidth * (compact ? 0.52 : 0.48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 23 : 27,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.65,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '$userName!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 23 : 27,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.65,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '👋',
                          style: TextStyle(fontSize: compact ? 18 : 21),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00A38E),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickScenesRow extends StatelessWidget {
  final int selectedIndex;
  final void Function(int index, String sceneName) onSelect;

  const _QuickScenesRow({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scenes = [
      {
        'title': 'Good\nMorning',
        'rawName': 'Good Morning',
        'image': 'assets/images/scene_morning_ref.png',
      },
      {
        'title': 'Good\nNight',
        'rawName': 'Good Night',
        'image': 'assets/images/scene_night_ref.png',
      },
      {
        'title': 'Movie\nTime',
        'rawName': 'Movie Time',
        'image': 'assets/images/scene_movie_ref.png',
      },
      {
        'title': 'Away\nMode',
        'rawName': 'Away Mode',
        'image': 'assets/images/scene_away_ref.png',
      },
    ];

    return SizedBox(
      height: 124,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(scenes.length, (idx) {
          final scene = scenes[idx];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: idx == scenes.length - 1 ? 0 : 10,
              ),
              child: _SceneCard(
                title: scene['title']!,
                imagePath: scene['image']!,
                isSelected: selectedIndex == idx,
                onTap: () => onSelect(idx, scene['rawName']!),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _SceneCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isSelected ? const Color(0xFFDDF7F3) : Colors.white;
    final border = isSelected
        ? const Color(0xFF86DDD1)
        : const Color(0xFFEAF0F2);
    final labelColor = isSelected
        ? const Color(0xFF00796B)
        : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: isSelected ? 1.2 : 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B0F172A),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_awesome_rounded,
                    size: 38,
                    color: isSelected
                        ? const Color(0xFF00A38E)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: labelColor,
                    height: 1.08,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertiesAndEnergySection extends StatelessWidget {
  final List<ManagedProperty> properties;
  final EnergyProvider energyProvider;

  const _PropertiesAndEnergySection({
    required this.properties,
    required this.energyProvider,
  });

  IconData _iconForProperty(ManagedProperty property) {
    final type = property.propertyType.toLowerCase();
    final category = property.category.toLowerCase();
    if (type.contains('apartment') ||
        type.contains('flat') ||
        category.contains('apartment')) {
      return Icons.apartment_rounded;
    }
    if (type.contains('villa') || category.contains('villa')) {
      return Icons.villa_rounded;
    }
    if (type.contains('office') ||
        category.contains('commercial') ||
        category.contains('business')) {
      return Icons.business_rounded;
    }
    return Icons.home_rounded;
  }

  String _statusForProperty({
    required int floorCount,
    required int deviceCount,
    required int onlineCount,
  }) {
    if (deviceCount > 0) {
      if (onlineCount > 0) {
        return '$onlineCount Active • $deviceCount ${deviceCount == 1 ? "Device" : "Devices"}';
      } else {
        return '$deviceCount ${deviceCount == 1 ? "Device" : "Devices"}';
      }
    }
    if (floorCount > 0) {
      return 'Online • $floorCount ${floorCount == 1 ? "Floor" : "Floors"}';
    }
    return 'Active • Ready';
  }

  Widget _buildPropertyCard(
    BuildContext context,
    ManagedProperty prop,
    PropertyProvider propertyProvider,
    DeviceProvider deviceProvider,
    AppUser? user,
  ) {
    final floors = propertyProvider.floorsFor(prop.id);
    final devices = deviceProvider.visibleDevicesForProperty(
      user,
      prop.name,
      propertyId: prop.id,
    );
    final onlineCount = devices
        .where((d) => d.status == DeviceStatus.online)
        .length;

    final status = _statusForProperty(
      floorCount: floors.length,
      deviceCount: devices.length,
      onlineCount: onlineCount,
    );

    return _PropertyCard(
      name: prop.name,
      status: status,
      icon: _iconForProperty(prop),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloorsScreen(propertyId: prop.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    Widget propertiesWidget;

    if (properties.isEmpty) {
      propertiesWidget = _AddPropertyFullCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomesScreen()),
        ),
      );
    } else if (properties.length == 1) {
      propertiesWidget = Row(
        children: [
          Expanded(
            child: _buildPropertyCard(
              context,
              properties[0],
              propertyProvider,
              deviceProvider,
              user,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AddPropertyCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomesScreen()),
              ),
            ),
          ),
        ],
      );
    } else if (properties.length == 2) {
      propertiesWidget = Row(
        children: [
          Expanded(
            child: _buildPropertyCard(
              context,
              properties[0],
              propertyProvider,
              deviceProvider,
              user,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPropertyCard(
              context,
              properties[1],
              propertyProvider,
              deviceProvider,
              user,
            ),
          ),
        ],
      );
    } else {
      propertiesWidget = SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: properties.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            if (index == properties.length) {
              return SizedBox(
                width: 165,
                child: _AddPropertyCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomesScreen()),
                  ),
                ),
              );
            }
            return SizedBox(
              width: 165,
              child: _buildPropertyCard(
                context,
                properties[index],
                propertyProvider,
                deviceProvider,
                user,
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        propertiesWidget,
        const SizedBox(height: 12),

        // Overall Energy Matrix Card (Full Width)
        _OverallEnergyMatrixCard(
          energyProvider: energyProvider,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnergyScreen()),
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final String name;
  final String status;
  final IconData icon;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.name,
    required this.status,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Soft Mint Icon Container + Subtle Arrow indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F7F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF00A38E),
                        size: 24,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF94A3B8),
                        size: 11,
                      ),
                    ),
                  ],
                ),
                // Bottom content: Property Name and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00A38E),
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

class _AddPropertyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPropertyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFC),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCCECE8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F7F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF00A38E),
                        size: 24,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF94A3B8),
                        size: 11,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Add Property',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '+ Setup new home',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00A38E),
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

class _AddPropertyFullCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPropertyFullCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFC),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCCECE8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                    Icons.add_home_work_rounded,
                    color: Color(0xFF00A38E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Add Your First Property',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Connect homes, floors & devices',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF94A3B8),
                    size: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallEnergyMatrixCard extends StatelessWidget {
  final EnergyProvider energyProvider;
  final VoidCallback onTap;

  const _OverallEnergyMatrixCard({
    required this.energyProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final liveWatts = energyProvider.instantPowerWatts > 0
        ? '${energyProvider.instantPowerWatts.toStringAsFixed(0)} W'
        : '2,480 W';

    final dailyKwh = energyProvider.totalKwh > 0
        ? '${energyProvider.totalKwh.toStringAsFixed(1)} kWh'
        : '18.4 kWh';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6F4F1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0800A38E),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Lightning Bolt Avatar, Title, and Redirect Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Overall Energy Matrix',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Live Grid & Backup Load',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFFB9EFE7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'View Matrix',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00A38E),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF00A38E),
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Row: 3 Telemetry Columns
                Row(
                  children: [
                    // Column 1: Live Load
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REAL-TIME LOAD',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                liveWatts,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00A38E),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Column 2: Today's Consumption
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY LOAD',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                dailyKwh,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Column 3: Status Badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC4EFE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'SYSTEM STATUS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00796B),
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '⚡ 98% Optimal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00A38E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mini Gradient Progress Bar & Tap prompt
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 5,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.65,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmartAssistantVoiceBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onTap;

  const _SmartAssistantVoiceBanner({
    required this.userName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3000A38E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Row(
            children: [
              // Robot avatar circular container
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/smart_robot.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/new_robot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $userName!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'How can I help you today?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Frosted Soundwave Audio Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceAssistantModal extends StatelessWidget {
  final String userName;

  const _VoiceAssistantModal({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9A7), Color(0xFF00A38E)],
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3500A38E),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Listening to $userName...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try asking:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          _commandChip(context, '⚡ "Turn on living room lights"'),
          const SizedBox(height: 8),
          _commandChip(context, '❄️ "Set AC temperature to 22°C"'),
          const SizedBox(height: 8),
          _commandChip(context, '🎬 "Activate Movie Time scene"'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _commandChip(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Executing: $text'),
            backgroundColor: const Color(0xFF00A38E),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
