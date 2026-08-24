import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'router.dart';
import 'firebase_options.dart';
import 'services/cloud_service.dart';
import 'presentation/providers/providers.dart';
import 'widgets/upi_notification_host.dart';
import 'services/upi_notification_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Cloud sync — initialises if Firebase has been configured via `flutterfire configure`.
  // The app runs fully offline otherwise.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    CloudService.markAvailable();
  } catch (e) {
    debugPrint('Firebase init skipped (offline mode): $e');
  }

  // Initialize local notifications (e.g. for mock testing)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(const ProviderScope(child: SangamApp()));
}

class SangamApp extends ConsumerWidget {
  const SangamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appInitProvider);
    final router = buildRouter();

    return UpiNotificationHost(
      onEvent: (context, ref, event) async {
        // Show a rich real-time SnackBar when a UPI payment arrives while app is in foreground
        try {
          final sender = event.sender.isNotEmpty && event.sender != 'Unknown'
              ? ' from ${event.sender}'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('₹${event.amount.toStringAsFixed(0)} received$sender'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => router.go('/sms-queue'),
              ),
            ),
          );

          // Also fire a local notification so it's visible in the notification shade
          await NotificationService.showSmsReceived(
            amount: event.amount,
            source: event.sender,
          );
        } catch (_) {}
      },
      child: MaterialApp.router(
        title: 'Sangam',
        theme: buildAppTheme(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
      ),
    );
  }
}
