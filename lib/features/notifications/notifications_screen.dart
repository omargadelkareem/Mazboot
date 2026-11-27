import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import 'notifications_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
          ? const _EmptyNotifications()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) =>
                  _NotificationCard(notification: state.items[index]),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          await context.read<NotificationsCubit>().markRead(notification.id);
        }
        if (notification.orderId != null && context.mounted) {
          context.push('/tracking/${notification.orderId}');
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.powderBlue,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : AppColors.navy.withOpacity(0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.powderBlue
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _timeLabel(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_none_rounded,
            size: 68,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text('مفيش إشعارات جديدة'),
        ],
      ),
    );
  }
}
