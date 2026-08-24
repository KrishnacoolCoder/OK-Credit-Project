import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../services/cloud_service.dart';
import '../../providers/providers.dart';

class MultiDeviceScreen extends ConsumerWidget {
  const MultiDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProfileProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Multi Device'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(gradient: AppGradients.saffron, shape: BoxShape.circle, boxShadow: AppShadows.saffron),
              child: const Icon(Icons.devices_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Run ${store.name.isEmpty ? "your shop" : store.name} together with your\nfamily, partners and staff — from their own phones.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 24),

          // Cloud sync status card
          if (CloudService.available && me?.effectiveShopId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cloud_done_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('Cloud sync active', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success)),
                ]),
                const SizedBox(height: 6),
                Text(
                  me!.isAdmin
                      ? 'Your customers, transactions, products and profile sync live to every device signed in to this shop.'
                      : 'You\'re seeing the same live ledger as the owner and every other staff member.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text2),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSyncInfo(context, me.isAdmin),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('How multi-device works'),
                  ),
                ),
              ]),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text('Cloud sync not connected', style: AppTextStyles.bodyMd.copyWith(color: AppColors.warning)),
                ]),
                const SizedBox(height: 6),
                Text(
                  'This build wasn\'t compiled with Firebase project keys, so your data stays on this device only.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text2),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSyncInfo(context, me?.isAdmin ?? false),
                    icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                    label: const Text('Learn more'),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          const Text('SIGNED-IN ACCOUNT', style: AppTextStyles.labelCaps),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight, width: 0.5),
            ),
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.surfaceTinted, shape: BoxShape.circle),
                child: const Icon(Icons.phone_android_rounded, color: AppColors.saffron, size: 20),
              ),
              title: Text(me?.name ?? 'This device', style: AppTextStyles.bodyMd),
              subtitle: Text(me == null ? 'This device' : '${me.username} · ${me.isAdmin ? 'Admin' : 'Staff'} · This device', style: AppTextStyles.caption),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSyncInfo(BuildContext context, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How multi-device works', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          Text(
            isAdmin
                ? 'Sign in on any phone with the same email and password you used to create this shop, and you\'ll see the same live data.\n\n'
                    'For staff, generate an invite code from Settings → Team. They\'ll create their own login and enter the code from their own phone, then see the same ledger.'
                : 'You signed up with your own email using an invite code from the owner. Sign in with that same email and password on any phone to see the same live ledger the owner and other staff use.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
          ),
        ]),
      ),
    );
  }
}
