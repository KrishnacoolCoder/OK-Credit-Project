import 'dart:async';

import 'package:flutter/services.dart';

class UpiNotificationEvent {
  final double amount;
  final String sender;
  final String appSource;
  final int timestamp;
  final String rawText;

  UpiNotificationEvent({
    required this.amount,
    required this.sender,
    required this.appSource,
    required this.timestamp,
    required this.rawText,
  });

  factory UpiNotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    return UpiNotificationEvent(
      amount: (map['amount'] as num).toDouble(),
      sender: (map['sender'] ?? 'Unknown').toString(),
      appSource: (map['appSource'] ?? '').toString(),
      timestamp: (map['timestamp'] as num).toInt(),
      rawText: (map['rawText'] ?? '').toString(),
    );
  }
}

class UpiNotificationService {
  static const EventChannel _channel = EventChannel('sangam/upi_notifications');

  Stream<UpiNotificationEvent> stream() {
    return _channel.receiveBroadcastStream().map((event) {
      return UpiNotificationEvent.fromMap(Map<dynamic, dynamic>.from(event as Map));
    });
  }
}
