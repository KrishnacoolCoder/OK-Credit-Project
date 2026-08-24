import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';

class SecurityCheckupScreen extends StatefulWidget {
  const SecurityCheckupScreen({super.key});

  @override
  State<SecurityCheckupScreen> createState() => _SecurityCheckupScreenState();
}

class _SecurityCheckupScreenState extends State<SecurityCheckupScreen> {
  bool _isScanning = false;
  bool _scanned = false;

  void _runScan() async {
    setState(() {
      _isScanning = true;
      _scanned = false;
    });
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanned = true;
      });
      context.showSnack('Security checkup completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Security Checkup'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            
            // Header Image/Animation
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: _isScanning
                      ? const CircularProgressIndicator(color: AppColors.saffron, strokeWidth: 4)
                      : null,
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _scanned ? AppColors.successBg : AppColors.saffronLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _scanned ? Icons.shield_rounded : Icons.security_rounded,
                    color: _scanned ? AppColors.success : AppColors.saffron,
                    size: 48,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Text(
              _isScanning ? 'Scanning your account...' : (_scanned ? 'Your account is secure' : 'Run a security checkup'),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We review your security settings to make sure your data is safe and recoverable.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Scan Button
            if (!_isScanning && !_scanned)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _runScan,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Start Scan'),
                ),
              ),

            // Results List
            if (_scanned)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _CheckItem(
                      icon: Icons.sync_rounded,
                      title: 'Cloud Backup Syncing',
                      subtitle: 'Your data is safely backed up to Google Drive.',
                      isOk: true,
                    ),
                    const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                    _CheckItem(
                      icon: Icons.phonelink_lock_rounded,
                      title: 'Trusted Devices',
                      subtitle: '1 device is currently logged into this store.',
                      isOk: true,
                    ),
                    const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                    _CheckItem(
                      icon: Icons.email_outlined,
                      title: 'Recovery Info',
                      subtitle: 'No recovery email set. Add one to secure your account.',
                      isOk: false,
                    ),
                  ],
                ),
              ),
              
             if (_scanned) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _runScan,
                  child: const Text('Scan Again'),
                )
             ]
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isOk;

  const _CheckItem({required this.icon, required this.title, required this.subtitle, required this.isOk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOk ? AppColors.successBg : AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isOk ? AppColors.success : AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
