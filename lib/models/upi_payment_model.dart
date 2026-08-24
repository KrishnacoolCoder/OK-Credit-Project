// lib/models/upi_payment_model.dart
import 'package:uuid/uuid.dart';

class UpiPaymentModel {
  final String id;
  final double amount;
  final String sender;
  final String appSource;
  final String rawText;
  final DateTime timestamp;

  UpiPaymentModel({
    required this.id,
    required this.amount,
    required this.sender,
    required this.appSource,
    required this.rawText,
    required this.timestamp,
  });

  factory UpiPaymentModel.fromMap(Map<dynamic, dynamic> map) {
    return UpiPaymentModel(
      id:        map['id']?.toString() ?? const Uuid().v4(),
      amount:    (map['amount'] as num?)?.toDouble() ?? 0.0,
      sender:    map['sender']?.toString() ?? 'Unknown',
      appSource: map['appSource']?.toString() ?? 'UPI',
      rawText:   map['rawText']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }
}
