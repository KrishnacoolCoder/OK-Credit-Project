import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings, onDidReceiveNotificationResponse: _onTap);
    _initialized = true;
  }

  static void _onTap(NotificationResponse r) {
    // Navigate to relevant screen based on payload
    // e.g. payload = 'customer:c1' → navigate to customer detail
  }

  static Future<void> showSmsReceived({required double amount, required String source}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '₹${amount.toStringAsFixed(0)} received via $source',
      'Tap to assign to a customer',
      const NotificationDetails(android: AndroidNotificationDetails(
        'sms_channel', 'UPI SMS Alerts',
        channelDescription: 'Alerts for incoming UPI payments',
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      )),
      payload: 'sms_queue',
    );
  }

  // DEV-HACK: Triggers a mock local notification that looks like a UPI payment
  // Our native NotificationListenerService will intercept this because we added our own package to the allowed list.
  static Future<void> showMockUpiPayment() async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'Mock GPay',
      'Dipanshu paid you ₹ 1,500',
      const NotificationDetails(android: AndroidNotificationDetails(
        'mock_channel', 'Mock UPI Payments',
        channelDescription: 'For dev testing only',
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      )),
    );
  }

  static Future<void> showOverdueReminder({required String customerName, required double balance, required String customerId}) async {
    await _plugin.show(
      customerId.hashCode,
      '$customerName hasn\'t paid',
      '₹${balance.toStringAsFixed(0)} due — tap to send reminder',
      const NotificationDetails(android: AndroidNotificationDetails(
        'overdue_channel', 'Overdue Reminders',
        channelDescription: 'Reminders for overdue customer payments',
        importance: Importance.defaultImportance,
        icon: '@mipmap/ic_launcher',
      )),
      payload: 'customer:$customerId',
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
