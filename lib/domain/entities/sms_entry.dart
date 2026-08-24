import 'transaction.dart';

class SmsEntry {
  final String id;
  final String rawSms;
  final double? parsedAmount;
  final TransactionType? parsedSource;
  final DateTime receivedAt;
  final String status; // 'pending', 'assigned', 'dismissed'
  final String? senderName; // Auto-detected from notification

  const SmsEntry({
    required this.id,
    required this.rawSms,
    this.parsedAmount,
    this.parsedSource,
    required this.receivedAt,
    this.status = 'pending',
    this.senderName,
  });
}

class ParsedKhataEntry {
  final String name;
  final double amount;
  final bool isCredit; // true = udhar given, false = payment received
  final String? note;

  const ParsedKhataEntry({
    required this.name,
    required this.amount,
    required this.isCredit,
    this.note,
  });
}

class DailyTotals {
  final double paytm;
  final double gpay;
  final double phonePe;
  final double cash;
  final double creditOut;
  final double creditIn;
  final int txnCount;

  const DailyTotals({
    this.paytm = 0, this.gpay = 0, this.phonePe = 0,
    this.cash = 0, this.creditOut = 0, this.creditIn = 0,
    this.txnCount = 0,
  });

  double get upiTotal => paytm + gpay + phonePe;
  double get totalIn => upiTotal + cash;
  double get netCredit => creditOut - creditIn;
}

class OverdueCustomer {
  final String customerId;
  final String customerName;
  final String? phone;
  final double balance;
  final int daysOverdue;

  const OverdueCustomer({
    required this.customerId,
    required this.customerName,
    this.phone,
    required this.balance,
    required this.daysOverdue,
  });
}
