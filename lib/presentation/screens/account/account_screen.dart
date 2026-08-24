import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../core/context_extensions.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out from Sangam Pro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    HapticFeedback.mediumImpact();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      await ref.read(authServiceProvider).clearSession();
      await ref.read(currentUserProvider.notifier).refresh();
      
      if (context.mounted) {
        Navigator.pop(context);
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        context.showSnack('Could not log out. Please try again.', isError: true);
      }
    }
  }

  void _shareApp() {
    Share.share(
      '📒 I use Sangam Pro to manage credit, UPI payments & customer ledger for my shop.\n\n'
      'Download Sangam Pro now 👇\n'
      'https://play.google.com/store/apps/details?id=com.sangam.pro',
      subject: 'Sangam Pro - Digital Ledger',
    );
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.sangam.pro');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(languageProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('My Account', 'मेरा खाता', hi)),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // User Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.saffron.withValues(alpha: 0.1),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: AppTextStyles.h2.copyWith(color: AppColors.saffron),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppTextStyles.h4),
                            const SizedBox(height: 4),
                            if (user.username.isNotEmpty)
                              Text(user.username, style: AppTextStyles.bodyMd.copyWith(color: AppColors.text3)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.isAdmin ? AppColors.successBg : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.isAdmin ? 'Admin' : 'Staff',
                                style: AppTextStyles.caption.copyWith(
                                  color: user.isAdmin ? AppColors.success : const Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(tr('SUBSCRIPTION & STORAGE', 'सदस्यता और स्टोरेज', hi), style: AppTextStyles.labelCaps),
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.star_rounded, color: AppColors.saffron),
                        title: const Text('Sangam Pro Plan'),
                        subtitle: const Text('Free Lifetime Pilot'),
                        trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_done_rounded, color: AppColors.success),
                        title: Text(tr('Cloud Backup', 'क्लाउड बैकअप', hi)),
                        subtitle: Text(tr('Your data is safely synced to the cloud.', 'आपका डेटा सुरक्षित है।', hi)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(tr('QUICK ACTIONS', 'त्वरित कार्य', hi), style: AppTextStyles.labelCaps),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.share_rounded, color: AppColors.saffron),
                        title: Text(tr('Share App', 'ऐप शेयर करें', hi)),
                        subtitle: Text(tr('Invite friends & fellow shopkeepers', 'दोस्तों को आमंत्रित करें', hi)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
                        onTap: _shareApp,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.star_rate_rounded, color: Color(0xFFFFA000)),
                        title: Text(tr('Rate on Play Store', 'Play Store पर रेट करें', hi)),
                        subtitle: Text(tr('Love Sangam? Give us 5 stars!', 'संगम पसंद है? 5 स्टार दें!', hi)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
                        onTap: _rateApp,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded, color: AppColors.info),
                        title: Text(tr('Help & Support', 'सहायता', hi)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
                        onTap: () => context.push('/help'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(tr('ACCOUNT ACTIONS', 'खाता सेटिंग्स', hi), style: AppTextStyles.labelCaps),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                        title: Text(tr('Logout', 'लॉग आउट', hi), style: const TextStyle(color: AppColors.error)),
                        onTap: () => _logout(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.text3),
                        title: Text(tr('Delete Account', 'खाता हटाएं', hi), style: const TextStyle(color: AppColors.text3)),
                        onTap: () {
                          context.showSnack('To delete your account, please contact support@sangam.app', isError: true);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // App version footer
                Center(
                  child: Column(
                    children: [
                      Text('Sangam Pro v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                          children: const [
                            TextSpan(text: 'Made with '),
                            TextSpan(text: '❤', style: TextStyle(color: Colors.red)),
                            TextSpan(text: ' in India'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
