import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/providers.dart';
import '../services/upi_notification_service.dart';

class UpiNotificationHost extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function(BuildContext context, WidgetRef ref, UpiNotificationEvent event) onEvent;

  const UpiNotificationHost({
    super.key,
    required this.child,
    required this.onEvent,
  });

  @override
  ConsumerState<UpiNotificationHost> createState() => _UpiNotificationHostState();
}

class _UpiNotificationHostState extends ConsumerState<UpiNotificationHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upiNotificationBridgeProvider).start(
        onEvent: (event) => widget.onEvent(context, ref, event),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
