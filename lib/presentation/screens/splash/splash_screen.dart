import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasLanguage = prefs.getBool('sangam_language_selected') ?? false;
    
    if (!hasLanguage) {
      if (mounted) context.go('/language');
      return;
    }

    final auth = ref.read(authServiceProvider);
    final hasAdmin = await auth.hasAdmin();
    if (!hasAdmin) {
      final onboarded = await ref.read(onboardedProvider.future);
      if (mounted) context.go(onboarded ? '/store-setup' : '/onboarding');
      return;
    }
    final session = await auth.getSessionUser();
    if (mounted) context.go(session != null ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 64,
                    height: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sangam',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.saffron,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Trusted by 50,00,000+ Businesses',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
            const Spacer(),
            
            // Security Badges Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SecurityBadge(icon: Icons.cloud_done_outlined, label: 'SECURED'),
                  _SecurityBadge(icon: Icons.lock_outline, label: 'SAFE & TRUSTED'),
                  _SecurityBadge(icon: Icons.vpn_key_outlined, label: 'PRIVATE'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                ),
                children: const [
                  TextSpan(text: 'Made With '),
                  TextSpan(text: '❤', style: TextStyle(color: Colors.red)),
                  TextSpan(text: ' In India 🇮🇳'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.info, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.text3,
          ),
        ),
      ],
    );
  }
}
