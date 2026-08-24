enum TransactionType { upiPaytm, upiGpay, upiPhonePe, cash, credit }
enum TransactionDirection { incoming, outgoing }

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.upiPaytm: return 'Paytm';
      case TransactionType.upiGpay: return 'GPay';
      case TransactionType.upiPhonePe: return 'PhonePe';
      case TransactionType.cash: return 'Cash';
      case TransactionType.credit: return 'Udhar';
    }
  }

  String get firestoreKey {
    switch (this) {
      case TransactionType.upiPaytm: return 'upi_paytm';
      case TransactionType.upiGpay: return 'upi_gpay';
      case TransactionType.upiPhonePe: return 'upi_phonePe';
      case TransactionType.cash: return 'cash';
      case TransactionType.credit: return 'credit';
    }
  }

  static TransactionType fromKey(String key) {
    switch (key) {
      case 'upi_gpay': return TransactionType.upiGpay;
      case 'upi_phonePe': return TransactionType.upiPhonePe;
      case 'cash': return TransactionType.cash;
      case 'credit': return TransactionType.credit;
      default: return TransactionType.upiPaytm;
    }
  }
}

class Transaction {
  final String id;
  final String? customerId;
  final String customerName;
  final double amount;
  final TransactionType type;
  final TransactionDirection direction;
  final String? note;
  final DateTime date;
  final String source; // 'manual', 'sms', 'photo'

  const Transaction({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.direction,
    this.note,
    required this.date,
    this.source = 'manual',
  });

  bool get isCredit => type == TransactionType.credit;
  bool get isIncoming => direction == TransactionDirection.incoming;

  Transaction copyWith({
    String? id, String? customerId, String? customerName, double? amount,
    TransactionType? type, TransactionDirection? direction, String? note,
    DateTime? date, String? source,
  }) => Transaction(
    id: id ?? this.id, customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName, amount: amount ?? this.amount,
    type: type ?? this.type, direction: direction ?? this.direction,
    note: note ?? this.note, date: date ?? this.date, source: source ?? this.source,
  );
}
