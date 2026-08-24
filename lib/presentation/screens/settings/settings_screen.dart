import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _useProIcon = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text('Settings', style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text1),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildListTile(
                icon: Icons.groups_rounded,
                title: 'Team & Staff',
                subtitle: 'Invite staff or manage your team',
                onTap: () => context.push('/team'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.translate_rounded,
                title: 'Language',
                trailing: Text('English', style: AppTextStyles.bodyMd.copyWith(color: AppColors.saffron, fontWeight: FontWeight.w600)),
                onTap: () => context.push('/language'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.exit_to_app_rounded,
                title: 'Change Mobile Number',
                onTap: () => context.push('/change-mobile'),
              ),

              _buildDivider(),
              _buildListTile(
                icon: Icons.photo_library_outlined,
                title: 'Backup Photos',
                subtitle: 'Backup on Google Drive or keep on phone',
                onTap: () => context.push('/backup'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'UPI QR for collection',
                subtitle: 'Share QR with customers to collect payme...',
                onTap: () => context.push('/upi-qr'),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildListTile(
                icon: Icons.cloud_done_outlined,
                title: 'Data Security Checkup',
                subtitle: 'Sync info, recovery number',
                onTap: () => context.push('/security-checkup'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.lock_outline_rounded,
                title: 'Security',
                subtitle: 'App lock, PIN, password, sign out',
                onTap: () => context.push('/security'),
              ),
            ]),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    backgroundColor: AppColors.errorBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to sign out? You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await ref.read(currentUserProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.saffron, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMd),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 0, color: AppColors.borderLight);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text('Sangam Pro v1.0.0', style: AppTextStyles.caption),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.caption.copyWith(color: AppColors.text2, fontWeight: FontWeight.w600),
            children: const [
              TextSpan(text: 'Made with '),
              TextSpan(text: '❤', style: TextStyle(color: Colors.red)),
              TextSpan(text: ' in India'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Sangam',
            applicationVersion: 'v1.0.0',
            applicationIcon: Container(
              margin: const EdgeInsets.all(16),
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.saffron, shape: BoxShape.circle),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
            ),
          ),
          child: Text(
            'Software Licenses',
            style: AppTextStyles.caption.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
