import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../services/notification_service.dart';

/// In-app notification center — shows all app events:
/// UPI payments, transactions added, overdue reminders, etc.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(appNotificationsProvider.notifier).clearAll(),
              child: Text('Clear All', style: AppTextStyles.btnSm.copyWith(color: AppColors.udhar)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.saffronLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.saffron),
                  ),
                  const SizedBox(height: 24),
                  Text('No notifications yet', style: AppTextStyles.h4.copyWith(color: AppColors.text1)),
                  const SizedBox(height: 8),
                  Text(
                    'All your app activity will appear here.\nUPI payments, new transactions, reminders & more.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.text3),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final notif = notifications[i];
                return _NotificationTile(notif: notif, index: i);
              },
            ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notif;
  final int index;
  const _NotificationTile({required this.notif, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconData = _iconForType(notif.type);
    final iconColor = _colorForType(notif.type);
    final bgColor = _bgColorForType(notif.type);
    final timeAgo = _timeAgo(notif.timestamp);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(appNotificationsProvider.notifier).remove(notif.id),
      background: Container(
        color: AppColors.udhar,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        color: notif.isRead ? Colors.white : const Color(0xFFF0F8F6),
        child: InkWell(
          onTap: () {
            ref.read(appNotificationsProvider.notifier).markRead(notif.id);
            if (notif.route != null) context.push(notif.route!);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(notif.body, style: AppTextStyles.bodySm.copyWith(color: AppColors.text3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(timeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.text4, fontSize: 11)),
                    ],
                  ),
                ),
                if (!notif.isRead)
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(color: AppColors.saffron, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.upiPayment: return Icons.account_balance_wallet_rounded;
      case NotificationType.transactionAdded: return Icons.receipt_long_rounded;
      case NotificationType.customerAdded: return Icons.person_add_alt_1_rounded;
      case NotificationType.overdueReminder: return Icons.warning_amber_rounded;
      case NotificationType.creditGiven: return Icons.arrow_upward_rounded;
      case NotificationType.paymentReceived: return Icons.arrow_downward_rounded;
      case NotificationType.system: return Icons.info_outline_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.upiPayment: return AppColors.gpay;
      case NotificationType.transactionAdded: return AppColors.saffron;
      case NotificationType.customerAdded: return AppColors.success;
      case NotificationType.overdueReminder: return AppColors.error;
      case NotificationType.creditGiven: return AppColors.udhar;
      case NotificationType.paymentReceived: return AppColors.success;
      case NotificationType.system: return AppColors.info;
    }
  }

  Color _bgColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.upiPayment: return AppColors.gpayBg;
      case NotificationType.transactionAdded: return AppColors.saffronLight;
      case NotificationType.customerAdded: return AppColors.successBg;
      case NotificationType.overdueReminder: return AppColors.errorBg;
      case NotificationType.creditGiven: return AppColors.udharBg;
      case NotificationType.paymentReceived: return AppColors.successBg;
      case NotificationType.system: return AppColors.infoBg;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }
}
