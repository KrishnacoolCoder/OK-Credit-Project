// =========================================================================
// PATCH: onboarding_screen.dart
// =========================================================================
// ADD import at top:
//   import '../../../services/upi_notification_service.dart';
//
// FIND your _done() method and ADD this block BEFORE context.go(...):
// =========================================================================

/*
  // Inside _done() — add before context.go('/store-setup'):
  final granted = await UpiNotificationService.isPermissionGranted();
  if (!granted && mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Enable Payment Auto-Capture'),
        content: const Text(
          'Sangam will automatically capture every UPI payment from '
          'PhonePe, GPay and Paytm.\n\n'
          "On the next screen, find 'Sangam' and toggle it ON.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip for now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UpiNotificationService.openPermissionSettings();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }
*/
