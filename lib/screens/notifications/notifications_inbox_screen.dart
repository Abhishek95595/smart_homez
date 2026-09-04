import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/client_notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_notification_provider.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications({bool refresh = true}) {
    final auth = context.read<AuthProvider>();
    final clientId = auth.resolvedClientUuid ?? auth.currentUser?.id ?? '';
    if (clientId.isNotEmpty) {
      context.read<ClientNotificationProvider>().fetchNotifications(
        clientId: clientId,
        refresh: refresh,
      );
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEE').format(date)}, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  void _confirmClearAll(BuildContext context, String clientId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.delete_sweep_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Clear All Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ClientNotificationProvider>().clearAll(
                clientId: clientId,
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final clientId = auth.resolvedClientUuid ?? auth.currentUser?.id ?? '';
    final notifProvider = context.watch<ClientNotificationProvider>();
    final notifications = notifProvider.filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title Block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              notifProvider.unreadCount > 0
                                  ? '${notifProvider.unreadCount} unread alert${notifProvider.unreadCount > 1 ? 's' : ''}'
                                  : 'All caught up',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: notifProvider.unreadCount > 0
                                    ? const Color(0xFF00A38E)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mark All Read Button
                      if (notifProvider.unreadCount > 0)
                        IconButton(
                          tooltip: 'Mark all as read',
                          icon: const Icon(
                            Icons.done_all_rounded,
                            color: Color(0xFF00A38E),
                            size: 22,
                          ),
                          onPressed: () {
                            notifProvider.markAllAsRead(clientId: clientId);
                          },
                        ),

                      // Clear All Button
                      if (notifProvider.notifications.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear all notifications',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                          onPressed: () => _confirmClearAll(context, clientId),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Filter Segmented Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterTabButton(
                            title: 'All Alerts',
                            count: notifProvider.notifications.length,
                            isSelected: !notifProvider.unreadOnlyFilter,
                            onTap: () => notifProvider.setUnreadOnlyFilter(
                              false,
                              clientId: clientId,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _FilterTabButton(
                            title: 'Unread Only',
                            count: notifProvider.unreadCount,
                            isSelected: notifProvider.unreadOnlyFilter,
                            isUnreadTab: true,
                            onTap: () => notifProvider.setUnreadOnlyFilter(
                              true,
                              clientId: clientId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00A38E),
                onRefresh: () async => _loadNotifications(refresh: true),
                child: notifProvider.isLoading && notifications.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A38E),
                        ),
                      )
                    : notifications.isEmpty
                    ? _buildEmptyState(notifProvider.unreadOnlyFilter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _NotificationTile(
                            notification: item,
                            formattedTime: _formatTimestamp(item.createdAt),
                            onTap: () {
                              if (!item.isRead) {
                                notifProvider.markAsRead(
                                  clientId: clientId,
                                  notificationId: item.id,
                                );
                              }
                            },
                            onDismissed: () {
                              notifProvider.deleteNotification(
                                clientId: clientId,
                                notificationId: item.id,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool unreadOnly) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB4EBE3), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 38,
                  color: Color(0xFF00A38E),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              unreadOnly ? 'No Unread Notifications' : 'No Notifications Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unreadOnly
                  ? 'You have read all your notifications.'
                  : 'Real-time device alerts, automation updates, and tenant notices will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabButton extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  final bool isUnreadTab;
  final VoidCallback onTap;

  const _FilterTabButton({
    required this.title,
    required this.count,
    required this.isSelected,
    this.isUnreadTab = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isUnreadTab
                      ? const Color(0xFF00A38E)
                      : (isSelected
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isUnreadTab ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final ClientNotification notification;
  final String formattedTime;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.formattedTime,
    required this.onTap,
    required this.onDismissed,
  });

  _CategoryStyle _getCategoryStyle(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return const _CategoryStyle(
          icon: Icons.local_fire_department_rounded,
          iconColor: Color(0xFFDC2626),
          bgColor: Color(0xFFFEE2E2),
          borderColor: Color(0xFFFECACA),
          tagColor: Color(0xFFDC2626),
          tagBg: Color(0xFFFEF2F2),
        );
      case NotificationCategory.plan:
        return const _CategoryStyle(
          icon: Icons.card_giftcard_rounded,
          iconColor: Color(0xFF7C3AED),
          bgColor: Color(0xFFEDE9FE),
          borderColor: Color(0xFFDDD6FE),
          tagColor: Color(0xFF7C3AED),
          tagBg: Color(0xFFF5F3FF),
        );
      case NotificationCategory.automation:
        return const _CategoryStyle(
          icon: Icons.bolt_rounded,
          iconColor: Color(0xFF2563EB),
          bgColor: Color(0xFFDBEAFE),
          borderColor: Color(0xFFBFDBFE),
          tagColor: Color(0xFF2563EB),
          tagBg: Color(0xFFEFF6FF),
        );
      case NotificationCategory.device:
        return const _CategoryStyle(
          icon: Icons.sensors_rounded,
          iconColor: Color(0xFF0D9488),
          bgColor: Color(0xFFCCFBF1),
          borderColor: Color(0xFF99F6E4),
          tagColor: Color(0xFF0D9488),
          tagBg: Color(0xFFF0FDFA),
        );
      case NotificationCategory.system:
        return const _CategoryStyle(
          icon: Icons.shield_outlined,
          iconColor: Color(0xFF475569),
          bgColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFFE2E8F0),
          tagColor: Color(0xFF475569),
          tagBg: Color(0xFFF8FAFC),
        );
      case NotificationCategory.general:
        return const _CategoryStyle(
          icon: Icons.notifications_active_rounded,
          iconColor: Color(0xFF00A38E),
          bgColor: Color(0xFFE6F7F5),
          borderColor: Color(0xFFB4EBE3),
          tagColor: Color(0xFF00A38E),
          tagBg: Color(0xFFF0FDFA),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getCategoryStyle(notification.category);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnread ? Colors.white : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnread
                    ? const Color(0xFFB4EBE3)
                    : const Color(0xFFE2E8F0),
                width: isUnread ? 1.3 : 1,
              ),
              boxShadow: isUnread
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00A38E).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Category Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: style.borderColor, width: 1),
                  ),
                  child: Center(
                    child: Icon(style.icon, color: style.iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Center Content Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Title + Unread Dot + Timestamp)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message Body
                      Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isUnread
                              ? const Color(0xFF334155)
                              : const Color(0xFF64748B),
                          fontWeight: isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Tag Pill + Unread Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: style.tagBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: style.tagColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              notification.category.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: style.tagColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Color(0xFF00A38E),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF007E72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _CategoryStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color tagColor;
  final Color tagBg;

  const _CategoryStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.tagColor,
    required this.tagBg,
  });
}
