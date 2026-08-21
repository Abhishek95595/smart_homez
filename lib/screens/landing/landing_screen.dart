import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _propertyTypesKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _featuresKey = GlobalKey();

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showProductDemo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ProductDemoSheet(
        onGetStarted: () {
          Navigator.pop(sheetContext);
          _openLogin();
        },
      ),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 66,
            backgroundColor: AppColors.background.withValues(alpha: 0.96),
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: _PageWidth(
              verticalPadding: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showLinks = constraints.maxWidth >= 760;
                  final compact = constraints.maxWidth < 380;
                  return Row(
                    children: [
                      const _Brand(),
                      const Spacer(),
                      if (showLinks) ...[
                        _NavLink(
                          label: 'Property types',
                          onTap: () => _scrollTo(_propertyTypesKey),
                        ),
                        _NavLink(
                          label: 'How it works',
                          onTap: () => _scrollTo(_howItWorksKey),
                        ),
                        _NavLink(
                          label: 'Features',
                          onTap: () => _scrollTo(_featuresKey),
                        ),
                        const SizedBox(width: 20),
                      ] else
                        PopupMenuButton<String>(
                          tooltip: 'Explore',
                          icon: const Icon(Icons.menu_rounded),
                          onSelected: (value) {
                            if (value == 'types') {
                              _scrollTo(_propertyTypesKey);
                            } else if (value == 'how') {
                              _scrollTo(_howItWorksKey);
                            } else if (value == 'features') {
                              _scrollTo(_featuresKey);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'types',
                              child: Text('Property types'),
                            ),
                            PopupMenuItem(
                              value: 'how',
                              child: Text('How it works'),
                            ),
                            PopupMenuItem(
                              value: 'features',
                              child: Text('Features'),
                            ),
                          ],
                        ),
                      if (!compact) ...[
                        TextButton(
                          onPressed: _openLogin,
                          child: const Text('Log in'),
                        ),
                        const SizedBox(width: 6),
                      ],
                      FilledButton(
                        onPressed: _openLogin,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: showLinks
                                ? 20
                                : compact
                                ? 12
                                : 14,
                            vertical: 12,
                          ),
                        ),
                        child: Text(showLinks ? 'Get started' : 'Start'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _HeroSection(
                  onGetStarted: _openLogin,
                  onSeeHow: _showProductDemo,
                ),
                _PropertyTypesSection(key: _propertyTypesKey),
                _HowItWorksSection(key: _howItWorksKey),
                _MiddleCta(
                  onGetStarted: _openLogin,
                  onWatchDemo: _showProductDemo,
                ),
                _FeaturesSection(key: _featuresKey),
                _BottomCta(onGetStarted: _openLogin),
                const _LandingFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageWidth extends StatelessWidget {
  final Widget child;
  final double verticalPadding;

  const _PageWidth({required this.child, this.verticalPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38FF7A18),
                blurRadius: 13,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 9),
        const Text(
          'Hasomi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      child: Text(label),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSeeHow;

  const _HeroSection({required this.onGetStarted, required this.onSeeHow});

  @override
  Widget build(BuildContext context) {
    return _PageWidth(
      verticalPadding: 66,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final copy = _HeroCopy(
            wide: wide,
            onGetStarted: onGetStarted,
            onSeeHow: onSeeHow,
          );
          const preview = _PropertiesPreview();

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 36), preview],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: 54),
              const Expanded(flex: 5, child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool wide;
  final VoidCallback onGetStarted;
  final VoidCallback onSeeHow;

  const _HeroCopy({
    required this.wide,
    required this.onGetStarted,
    required this.onSeeHow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Now supporting offices & multi-unit buildings',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'One app to run your '),
              TextSpan(
                text: 'homes,\napartments,\nand offices',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: wide ? 45 : 36,
            height: 1.06,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Add any property, map its floors and rooms, connect your devices, '
          'and automate the rest — whether it is a family home or a '
          '12-floor office.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: onGetStarted,
              child: const Text('Get started free'),
            ),
            OutlinedButton(
              onPressed: onSeeHow,
              child: const Text('See how it works'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _TrustItem(
              icon: Icons.shield_outlined,
              label: 'End-to-end encryption*',
            ),
            _TrustItem(
              icon: Icons.grid_view_rounded,
              label: '150+ device integrations*',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '*Available when the production backend and certified device '
          'connectors are configured.',
          style: TextStyle(color: AppColors.textFaint, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textFaint),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _PropertiesPreview extends StatelessWidget {
  const _PropertiesPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1014161F),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR PROPERTIES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.circle, color: AppColors.success, size: 8),
            ],
          ),
          SizedBox(height: 13),
          _PreviewProperty(
            icon: Icons.home_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primarySoft,
            name: 'Lakeview Home',
            details: '4 floors · 18 rooms · 62 devices',
            status: 'Online',
            statusColor: AppColors.success,
          ),
          SizedBox(height: 9),
          _PreviewProperty(
            icon: Icons.apartment_outlined,
            iconColor: AppColors.accentTeal,
            iconBackground: Color(0xFFEFEBFF),
            name: 'Willow Apartments',
            details: '6 floors · 24 units · 210 devices',
            status: 'Online',
            statusColor: AppColors.success,
          ),
          SizedBox(height: 9),
          _PreviewProperty(
            icon: Icons.business_center_outlined,
            iconColor: Color(0xFF3B82F6),
            iconBackground: Color(0xFFEAF1FF),
            name: 'AuraBrain HQ',
            details: '3 floors · 40 workspaces · 96 devices',
            status: 'Business hours',
            statusColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PreviewProperty extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String name;
  final String details;
  final String status;
  final Color statusColor;

  const _PreviewProperty({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.name,
    required this.details,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyTypesSection extends StatelessWidget {
  const _PropertyTypesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = [
      _PropertyTypeData(
        icon: Icons.home_outlined,
        color: AppColors.primary,
        background: AppColors.primarySoft,
        title: 'Homes',
        description:
            'Houses, villas, and farmhouses — rooms, family routines, and everyday automation.',
        points: ['Room-by-room device control', 'Family schedules & routines'],
      ),
      _PropertyTypeData(
        icon: Icons.apartment_outlined,
        color: AppColors.accentTeal,
        background: Color(0xFFEFEBFF),
        title: 'Apartments',
        description:
            'Multi-unit buildings with per-unit access, shared amenities, and building-wide oversight.',
        points: ['Unit-level access control', 'Shared amenity scheduling'],
      ),
      _PropertyTypeData(
        icon: Icons.business_center_outlined,
        color: Color(0xFF3B82F6),
        background: Color(0xFFEAF1FF),
        title: 'Offices',
        description:
            'Business hours, occupancy limits, desks and meeting rooms — built for facility managers.',
        points: ['Business-hours automation', 'Occupancy & capacity tracking'],
      ),
    ];

    return Container(
      color: AppColors.background,
      child: _PageWidth(
        verticalPadding: 72,
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'BUILT FOR EVERY PROPERTY TYPE',
              title: 'Homes, apartments, and offices — one platform',
              subtitle:
                  'The setup adapts to what you are managing, so you only see fields that matter.',
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = _cardWidth(
                  constraints.maxWidth,
                  desktopColumns: 3,
                  tabletColumns: 2,
                );
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: width,
                          child: _PropertyTypeCard(data: card),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyTypeData {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String description;
  final List<String> points;

  const _PropertyTypeData({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.description,
    required this.points,
  });
}

class _PropertyTypeCard extends StatelessWidget {
  final _PropertyTypeData data;

  const _PropertyTypeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 225),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            data.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 13),
          ...data.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData(
        number: '1',
        title: 'Add your property',
        description:
            'Tell us if it is residential or commercial — the form adjusts the fields that matter.',
      ),
      _StepData(
        number: '2',
        title: 'Map floors & rooms',
        description:
            'Lay out floors, then rooms, units, or workspaces underneath each one.',
      ),
      _StepData(
        number: '3',
        title: 'Connect devices',
        description:
            'Pair lights, locks, sensors, and thermostats, then automate however you like.',
      ),
    ];

    return Container(
      color: AppColors.surfaceElevated,
      child: _PageWidth(
        verticalPadding: 72,
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'HOW IT WORKS',
              title: 'Set up in three steps',
            ),
            const SizedBox(height: 34),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = _cardWidth(
                  constraints.maxWidth,
                  desktopColumns: 3,
                  tabletColumns: 2,
                );
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: steps
                      .map(
                        (step) => SizedBox(
                          width: width,
                          child: _StepCard(data: step),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final String number;
  final String title;
  final String description;

  const _StepData({
    required this.number,
    required this.title,
    required this.description,
  });
}

class _StepCard extends StatelessWidget {
  final _StepData data;

  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              data.number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            data.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const features = [
      _FeatureData(
        icon: Icons.bolt_outlined,
        title: 'Automations',
        description: 'Rules triggered by time, occupancy, or sensor data.',
      ),
      _FeatureData(
        icon: Icons.mic_none_rounded,
        title: 'Voice assistants',
        description:
            'Connect major voice platforms from one integration setup.',
      ),
      _FeatureData(
        icon: Icons.query_stats_rounded,
        title: 'Energy insights',
        description: 'Track usage per floor, unit, or device over time.',
      ),
      _FeatureData(
        icon: Icons.location_on_outlined,
        title: 'Multi-property dashboard',
        description: 'See every home, unit, and office in one view.',
      ),
      _FeatureData(
        icon: Icons.shield_outlined,
        title: 'Access control',
        description: 'Grant and revoke access per tenant, room, or team.',
      ),
      _FeatureData(
        icon: Icons.notifications_none_rounded,
        title: 'Real-time alerts',
        description: 'Get notified the moment something needs attention.',
      ),
    ];

    return _PageWidth(
      verticalPadding: 72,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'FEATURES',
            title: 'Everything a property manager needs',
          ),
          const SizedBox(height: 34),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = _cardWidth(
                constraints.maxWidth,
                desktopColumns: 3,
                tabletColumns: 2,
              );
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: features
                    .map(
                      (feature) => SizedBox(
                        width: width,
                        child: _FeatureCard(data: feature),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiddleCta extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onWatchDemo;

  const _MiddleCta({required this.onGetStarted, required this.onWatchDemo});

  @override
  Widget build(BuildContext context) {
    return _PageWidth(
      verticalPadding: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD7AD)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final copy = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See Hasomi in action',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Explore the setup flow or create your first property now.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onWatchDemo,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 19),
                  label: const Text('Watch interactive demo'),
                ),
                FilledButton(
                  onPressed: onGetStarted,
                  child: const Text('Get started free'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const SizedBox(height: 18), actions],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 24),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductDemoSheet extends StatefulWidget {
  final VoidCallback onGetStarted;

  const _ProductDemoSheet({required this.onGetStarted});

  @override
  State<_ProductDemoSheet> createState() => _ProductDemoSheetState();
}

class _ProductDemoSheetState extends State<_ProductDemoSheet> {
  static const _slides = [
    _DemoSlideData(
      icon: Icons.add_home_work_outlined,
      title: '1. Add any property',
      description:
          'Choose Residential or Commercial. Hasomi changes the form '
          'for houses, apartments, offices, retail spaces and warehouses.',
      points: [
        'Select the property category and type',
        'Add location, timezone and business hours',
        'Review the live property preview',
      ],
    ),
    _DemoSlideData(
      icon: Icons.account_tree_outlined,
      title: '2. Map floors and rooms',
      description:
          'Build the complete structure underneath every property and keep '
          'residential rooms separate from units and workspaces.',
      points: [
        'Property → Floor → Room or workspace',
        'Unit-level access for apartments',
        'Shared and common-area organisation',
      ],
    ),
    _DemoSlideData(
      icon: Icons.devices_other_rounded,
      title: '3. Connect and automate',
      description:
          'Register devices, monitor safety and energy, then create routines '
          'that respond to schedules, occupancy and sensor data.',
      points: [
        'Lights, locks, sensors and thermostats',
        'Morning, Night, Away and custom scenes',
        'Real-time safety alerts and energy insights',
      ],
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      widget.onGetStarted();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Hasomi works',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'A quick interactive product tour',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close demo',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _DemoSlide(data: _slides[index]),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...List.generate(
                  _slides.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: dotIndex == _index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(
                      color: dotIndex == _index
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onGetStarted,
                  child: const Text('Skip to setup'),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: _next,
                  icon: Icon(
                    _index == _slides.length - 1
                        ? Icons.rocket_launch_outlined
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _index == _slides.length - 1 ? 'Get started' : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoSlideData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> points;

  const _DemoSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });
}

class _DemoSlide extends StatelessWidget {
  final _DemoSlideData data;

  const _DemoSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(data.icon, color: Colors.white, size: 31),
            ),
            const SizedBox(height: 22),
            Text(
              data.title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              data.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            ...data.points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 23,
                      height: 23,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(data.icon, color: AppColors.textSecondary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _BottomCta({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return _PageWidth(
      verticalPadding: 58,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 34),
        decoration: BoxDecoration(
          color: AppColors.sideBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final copy = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to automate your property?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add your first home, apartment, or office in under two minutes.',
                  style: TextStyle(color: AppColors.sideText, fontSize: 12.5),
                ),
              ],
            );
            final button = FilledButton(
              onPressed: onGetStarted,
              child: const Text('Get started free'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const SizedBox(height: 22), button],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 24),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: const _PageWidth(
        verticalPadding: 28,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: [
            _Brand(),
            Text(
              '© 2026 AuraBrain Technologies · Privacy · Terms',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        children: [
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              height: 1.15,
              letterSpacing: -0.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double _cardWidth(
  double available, {
  required int desktopColumns,
  required int tabletColumns,
}) {
  const gap = 18.0;
  if (available >= 900) {
    return (available - gap * (desktopColumns - 1)) / desktopColumns;
  }
  if (available >= 560) {
    return (available - gap * (tabletColumns - 1)) / tabletColumns;
  }
  return available;
}
