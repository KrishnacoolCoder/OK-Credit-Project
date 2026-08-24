import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../providers/providers.dart';
import '../../../services/notification_access_service.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});
  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> with WidgetsBindingObserver {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission(initial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission({bool initial = false}) async {
    final enabled = await NotificationAccessService().isEnabled();
    final postStatus = await Permission.notification.status;
    
    if (mounted) {
      if (enabled && postStatus.isGranted) {
        context.go('/dashboard');
      } else {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _requestPermission() async {
    // 1. Request POST_NOTIFICATIONS
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // 2. Request Notification Access (for reading SMS from notification)
    final enabled = await NotificationAccessService().isEnabled();
    if (!enabled) {
      await NotificationAccessService().openSettings();
    } else {
      _checkPermission();
    }
  }

  void _skip() {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(languageProvider);

    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.saffron)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppGradients.saffron,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.saffron,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 60),
              ).animate().scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ).fadeIn(),
              
              const SizedBox(height: 40),
              
              Text(
                tr('Get notifications', 'सूचनाएं पाएं', hi),
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).slideY(begin: 0.2, end: 0).fadeIn(),
              
              const SizedBox(height: 16),
              
              Text(
                tr(
                  'We need notification access to automatically track UPI payments (PhonePe, GPay, Paytm) and give you important alerts.',
                  'हमें UPI भुगतानों (PhonePe, GPay, Paytm) को स्वचालित रूप से ट्रैक करने और आपको महत्वपूर्ण अलर्ट देने के लिए अधिसूचना पहुंच की आवश्यकता है।',
                  hi,
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2, height: 1.5),
              ).animate(delay: 300.ms).slideY(begin: 0.2, end: 0).fadeIn(),

              const Spacer(flex: 2),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(
                        tr('Skip', 'छोड़ें', hi),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins', color: AppColors.text2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(
                        tr('Allow', 'अनुमति दें', hi),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).slideY(begin: 0.2, end: 0).fadeIn(),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
