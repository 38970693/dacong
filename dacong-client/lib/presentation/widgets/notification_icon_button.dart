import 'package:flutter/material.dart';
import '../providers/notification_provider.dart';
import '../pages/notifications/notifications_page.dart';

/// 通知图标组件（带未读数量徽章）
class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  late final NotificationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = notificationProvider;
    _provider.addListener(_onProviderChange);
    // 初始加载未读数量
    Future.microtask(() => _provider.loadNotifications(unreadOnly: false));
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _provider.unreadCount;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ),
        );
      },
      tooltip: '通知',
    );
  }
}
