import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/context_extensions.dart';
import '../../providers/providers.dart';
import '../../widgets/sangam_logo.dart';

class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});
  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      await ref.read(currentUserProvider.notifier).refresh();
      if (!mounted) return;
      
      if (user != null) {
        context.go('/permissions');
        context.showSnack('Welcome back, ${user.name}!');
      } else {
        // Check if user exists but has no shop, or is entirely new
        final userType = await ref.read(authServiceProvider).getUserType();
        if (!mounted) return;
        if (userType == 'new') {
          context.go('/store-setup');
        } else {
          context.go('/permissions');
        }
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnack('Google Sign-In failed or was cancelled', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openLanguageSelector() {
    context.push('/language');
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Language Selector ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _openLanguageSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTinted,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.borderLight, width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.saffron)),
                            const SizedBox(width: 6),
                            Text(hi ? 'हिंदी' : 'English', style: AppTextStyles.btnSm.copyWith(color: AppColors.text2)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.text3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 60),

                // ── App Logo Center ──
                Center(
                  child: SangamLogo(size: 110)
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOutSine),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 40),

                // ── Heading ──
                Center(
                  child: Text(
                    tr('Welcome to Sangam', 'संगम में आपका स्वागत है', hi),
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ),
                
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr('Secure and fast login with your Google account.', 'अपने Google खाते के साथ सुरक्षित और तेज़ लॉगिन।', hi),
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.text3),
                    textAlign: TextAlign.center,
                  ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 56),

                // ── Continue button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.text1,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.saffron,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tr('Continue with Google', 'Google के साथ आगे बढ़ें', hi),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // ── Staff invite link ──
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => context.push('/staff-signup'),
                    child: Text(
                      tr('Have an invite code? Join as staff', 'इनवाइट कोड है? स्टाफ के रूप में जुड़ें', hi),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.saffron,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
