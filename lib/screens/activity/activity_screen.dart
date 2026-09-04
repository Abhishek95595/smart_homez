import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import 'activity_theme.dart';
import 'widgets/activity_detail_modal.dart';
import 'widgets/activity_empty_state.dart';
import 'widgets/activity_event_card.dart';
import 'widgets/activity_filter_rail.dart';
import 'widgets/activity_hero_card.dart';
import 'widgets/activity_search_bar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();
  ActivityFilter _filter = ActivityFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ActivityTheme.of(context);
    final alertProvider = context.watch<AlertProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserName = auth.currentUser?.name ?? 'Operator';
    final activities = _filteredActivities(alertProvider.alerts);

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.panel,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        leading: canPop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colors.textPrimary,
                    size: 28,
                  ),
                  tooltip: 'Menu',
                  onPressed: () => openAppDrawer(ctx),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Stream',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'LIVE SYSTEM EVENT FEED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.accent,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    // Live System Events Hero Status Card
                    ActivityHeroCard(alertProvider: alertProvider),
                    const SizedBox(height: 14),

                    // Search Input
                    ActivitySearchBar(
                      controller: _searchController,
                      onChanged: () => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Rail
                    ActivityFilterRail(
                      selected: _filter,
                      onSelected: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (activities.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: ActivityEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ActivityEventCard(
                        alert: activities[index],
                        userName: currentUserName,
                        onAcknowledge: () => alertProvider.acknowledge(
                          activities[index],
                          currentUserName,
                        ),
                        onResolve: () => alertProvider.resolve(
                          activities[index],
                          currentUserName,
                        ),
                        onTap: () => _showActivityDetailSheet(
                          context,
                          activities[index],
                          currentUserName,
                        ),
                      ),
                    ),
                    childCount: activities.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<AppAlert> _filteredActivities(List<AppAlert> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((alert) {
      final matchesFilter = switch (_filter) {
        ActivityFilter.all => true,
        ActivityFilter.newItems => !alert.acknowledged && !alert.resolved,
        ActivityFilter.acknowledged => alert.acknowledged && !alert.resolved,
        ActivityFilter.resolved => alert.resolved,
        ActivityFilter.critical =>
          alert.severity == AlertSeverity.critical && !alert.resolved,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return alert.alertType.label.toLowerCase().contains(query) ||
          alert.location.toLowerCase().contains(query) ||
          alert.deviceId.toLowerCase().contains(query) ||
          alert.severity.label.toLowerCase().contains(query);
    }).toList();
  }

  void _showActivityDetailSheet(
    BuildContext context,
    AppAlert alert,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ActivityDetailModal(alert: alert, userName: userName),
    );
  }
}
