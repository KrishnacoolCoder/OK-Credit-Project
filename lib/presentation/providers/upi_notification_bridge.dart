import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sms_entry.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../services/notification_service.dart';
import '../../services/upi_notification_service.dart';
import 'providers.dart';

final upiNotificationServiceProvider = Provider<UpiNotificationService>((ref) {
  return UpiNotificationService();
});

final upiNotificationBridgeProvider = Provider<UpiNotificationBridge>((ref) {
  return UpiNotificationBridge(ref);
});

class UpiNotificationBridge {
  UpiNotificationBridge(this._ref);

  final Ref _ref;
  StreamSubscription<UpiNotificationEvent>? _sub;
  bool _started = false;

  void start({required Future<void> Function(UpiNotificationEvent event) onEvent}) {
    if (_started) return;
    _started = true;

    _sub = _ref.read(upiNotificationServiceProvider).stream().listen((event) async {
      final source = _mapSource(event.appSource, event.rawText);
      final entry = SmsEntry(
        id: '${event.timestamp}_${event.rawText.hashCode}',
        rawSms: event.rawText,
        parsedAmount: event.amount,
        parsedSource: source,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(event.timestamp),
        status: 'pending',
      );

      _ref.read(smsQueueProvider.notifier).add(entry);
      await NotificationService.showSmsReceived(
        amount: event.amount,
        source: _labelFor(source),
      );
      await onEvent(event);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  entity.TransactionType _mapSource(String appSource, String rawText) {
    final app = appSource.toLowerCase();
    final text = rawText.toLowerCase();

    if (app.contains('phonepe') || text.contains('phonepe')) {
      return entity.TransactionType.upiPhonePe;
    }
    if (app.contains('paytm') || text.contains('paytm')) {
      return entity.TransactionType.upiPaytm;
    }
    if (app.contains('gpay') || app.contains('paisa') || text.contains('google pay') || text.contains('gpay')) {
      return entity.TransactionType.upiGpay;
    }
    return entity.TransactionType.upiGpay;
  }

  String _labelFor(entity.TransactionType type) {
    switch (type) {
      case entity.TransactionType.upiPaytm:
        return 'Paytm';
      case entity.TransactionType.upiPhonePe:
        return 'PhonePe';
      case entity.TransactionType.upiGpay:
        return 'GPay';
      default:
        return 'UPI';
    }
  }
}
