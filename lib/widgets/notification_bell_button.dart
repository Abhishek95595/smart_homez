import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/client_notification_provider.dart';
import '../screens/notifications/notifications_inbox_screen.dart';

class NotificationBellButton extends StatefulWidget {
  final Color iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const NotificationBellButton({
    super.key,
    this.iconColor = const Color(0xFF0F172A),
    this.iconSize = 27,
    this.padding = const EdgeInsets.only(right: 8),
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final clientId = auth.resolvedClientUuid ?? auth.currentUser?.id ?? '';
      if (clientId.isNotEmpty) {
        context.read<ClientNotificationProvider>().fetchUnreadCount(
          clientId: clientId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<ClientNotificationProvider>();
    final unreadCount = notifProvider.unreadCount;

    return Padding(
      padding: widget.padding,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsInboxScreen(),
                ),
              );
            },
          ),
          if (unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  padding: unreadCount > 9
                      ? const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        )
                      : const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
