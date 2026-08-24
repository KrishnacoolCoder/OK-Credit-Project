import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType {
  upiPayment,
  transactionAdded,
  customerAdded,
  overdueReminder,
  creditGiven,
  paymentReceived,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? route;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.route,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? route,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
    );
  }
}

class AppNotificationsNotifier extends StateNotifier<List<AppNotification>> {
  AppNotificationsNotifier() : super([]);

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  void add(AppNotification notification) {
    state = [notification, ...state];
  }
}

final appNotificationsProvider = StateNotifierProvider<AppNotificationsNotifier, List<AppNotification>>((ref) {
  return AppNotificationsNotifier();
});
