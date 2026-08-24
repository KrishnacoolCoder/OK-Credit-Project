import 'dart:convert';
import 'package:flutter/services.dart';
import 'upi_notification_service.dart';

class NotificationAccessService {
  static const MethodChannel _channel = MethodChannel('sangam/notification_access');

  Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
      return true;
    } on MissingPluginException {
      return false;
    }
  }

  Future<List<UpiNotificationEvent>> getQueuedPayments() async {
    try {
      final String? result = await _channel.invokeMethod<String>('getAndClearQueuedPayments');
      if (result == null) return [];
      final List<dynamic> list = jsonDecode(result);
      return list.map((e) => UpiNotificationEvent.fromMap(e as Map)).toList();
    } on MissingPluginException {
      return [];
    } catch (e) {
      return [];
    }
  }
}
