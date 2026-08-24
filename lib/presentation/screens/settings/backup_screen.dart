import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _autoBackup = true;
  bool _isBackingUp = false;

  void _runBackup() async {
    setState(() => _isBackingUp = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isBackingUp = false);
      context.showSnack('Backup completed successfully to Google Drive');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Backup Photos & Data'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 64, color: AppColors.saffron),
                  const SizedBox(height: 16),
                  const Text('Last Backup', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  const Text('Today at 10:45 AM', style: AppTextStyles.h3),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _runBackup,
                      icon: _isBackingUp
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.backup_rounded, size: 20),
                      label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('BACKUP SETTINGS', style: AppTextStyles.labelCaps),
            const SizedBox(height: 12),
            
            // Settings List
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.autorenew_rounded, color: AppColors.saffron),
                    title: const Text('Auto-Backup', style: AppTextStyles.bodyMd),
                    subtitle: const Text('Backup daily over Wi-Fi', style: AppTextStyles.caption),
                    trailing: Switch(
                      value: _autoBackup,
                      onChanged: (v) => setState(() => _autoBackup = v),
                      activeColor: AppColors.saffron,
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 0, color: AppColors.borderLight),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.add_to_drive_rounded, color: AppColors.saffron),
                    title: const Text('Google Account', style: AppTextStyles.bodyMd),
                    subtitle: const Text('store@gmail.com', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
                    onTap: () => context.showSnack('Linked to your signed-in Google account'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 0, color: AppColors.borderLight),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.sd_storage_outlined, color: AppColors.saffron),
                    title: const Text('Local Phone Backup', style: AppTextStyles.bodyMd),
                    subtitle: const Text('Save a copy to your phone', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
                    onTap: () => context.showSnack('Local backup downloaded'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
