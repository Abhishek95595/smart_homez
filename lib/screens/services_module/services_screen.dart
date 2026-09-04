import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/ticket.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final canBroadcast = role.canAdminister;
    final canManageTickets = role.canManageTickets;

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => AppNavigationLeading.drawer(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Society Services'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          onTap: (i) => setState(() => _currentTab = i),
          tabs: const [
            Tab(text: 'Tickets'),
            Tab(text: 'Broadcasts'),
          ],
        ),
      ),
      floatingActionButton: (_currentTab == 1 && !canBroadcast)
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _currentTab == 1
                  ? _showBroadcastSheet(context)
                  : _showReportIssueSheet(context),
              child: Icon(
                _currentTab == 1 ? Icons.campaign_rounded : Icons.add_rounded,
              ),
            ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _TicketsTab(canManage: canManageTickets),
            const _BroadcastsTab(),
          ],
        ),
      ),
    );
  }

  void _showBroadcastSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Post Broadcast Notice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'Notice title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Message'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final user = context.read<AuthProvider>().currentUser;
                    context.read<TicketProvider>().addBroadcast(
                      BroadcastNotice(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        message: msgCtrl.text.trim(),
                        postedAt: DateTime.now(),
                        postedBy: user?.name ?? 'Admin',
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Post'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportIssueSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TicketCategory category = TicketCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report an Issue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'Issue title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: TicketCategory.values.map((c) {
                      final selected = c == category;
                      return ChoiceChip(
                        label: Text(c.label),
                        selected: selected,
                        onSelected: (_) => setState(() => category = c),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final user = context.read<AuthProvider>().currentUser;
                        context.read<TicketProvider>().addTicket(
                          ServiceTicket(
                            id: const Uuid().v4(),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: category,
                            raisedBy: user?.name ?? 'You',
                            location: user?.unitLabel ?? 'Unknown',
                            createdAt: DateTime.now(),
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketsTab extends StatelessWidget {
  final bool canManage;
  const _TicketsTab({this.canManage = false});

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.primary;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<TicketProvider>().tickets;
    final df = DateFormat('MMM d');

    if (tickets.isEmpty) {
      return const Center(
        child: Text(
          'No tickets yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: tickets.length,
      itemBuilder: (context, i) {
        final t = tickets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(t.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.status.label,
                      style: TextStyle(
                        color: _statusColor(t.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                t.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      t.category.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    df.format(t.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (canManage && t.status != TicketStatus.closed) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Update:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: TicketStatus.values
                            .where((s) => s != t.status)
                            .map(
                              (s) => ActionChip(
                                label: Text(
                                  s.label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () => context
                                    .read<TicketProvider>()
                                    .updateStatus(t, s),
                                backgroundColor: AppColors.surfaceElevated,
                                side: const BorderSide(
                                  color: AppColors.divider,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BroadcastsTab extends StatelessWidget {
  const _BroadcastsTab();

  @override
  Widget build(BuildContext context) {
    final broadcasts = context.watch<TicketProvider>().broadcasts;
    final df = DateFormat('MMM d, h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: broadcasts.length,
      itemBuilder: (context, i) {
        final b = broadcasts[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                b.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${b.postedBy} • ${df.format(b.postedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
