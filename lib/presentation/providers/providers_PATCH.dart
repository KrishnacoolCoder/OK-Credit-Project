// =========================================================================
// PATCH: providers.dart
// =========================================================================
// ADD this import at the top of providers.dart:
//   import '../../services/upi_notification_service.dart';
//   import '../../models/upi_payment_model.dart';
//   import 'dart:async';
//
// REPLACE the SmsAutoReadNotifier class + smsAutoReadProvider with:
// =========================================================================

/*
class UpiAutoReadNotifier extends StateNotifier<bool> {
  final Ref _ref;
  static const _key = 'sangam_upi_auto';
  StreamSubscription<UpiPaymentModel>? _sub;

  UpiAutoReadNotifier(this._ref) : super(false) { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_key) ?? false) { state = true; _startListening(); }
  }

  void _startListening() {
    _sub?.cancel();
    _sub = UpiNotificationService.paymentStream.listen((payment) {
      final entry = SmsEntry(
        id:           payment.id,
        rawSms:       payment.rawText,
        parsedAmount: payment.amount,
        parsedSource: _toType(payment.appSource),
        receivedAt:   payment.timestamp,
        status:       'pending',
      );
      _ref.read(smsQueueProvider.notifier).add(entry);
    });
  }

  entity.TransactionType _toType(String source) {
    switch (source) {
      case 'Google Pay': return entity.TransactionType.upiGpay;
      case 'PhonePe':    return entity.TransactionType.upiPhonePe;
      case 'Paytm':      return entity.TransactionType.upiPaytm;
      default:           return entity.TransactionType.upiOther;
    }
  }

  Future<bool> enable() async {
    final granted = await UpiNotificationService.isPermissionGranted();
    if (!granted) { await UpiNotificationService.openPermissionSettings(); return false; }
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
    state = true;
    _startListening();
    return true;
  }

  Future<void> disable() async {
    _sub?.cancel();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, false);
    state = false;
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

final smsAutoReadProvider = StateNotifierProvider<UpiAutoReadNotifier, bool>(
  (ref) => UpiAutoReadNotifier(ref),
);
*/
