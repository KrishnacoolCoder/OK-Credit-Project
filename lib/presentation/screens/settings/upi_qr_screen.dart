import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';
import '../../../core/context_extensions.dart';

class UpiQrScreen extends ConsumerWidget {
  const UpiQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store UPI QR'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The QR Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppShadows.lg,
                ),
                child: Column(
                  children: [
                    Text(
                      store.name.isEmpty ? 'My Store' : store.name,
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan to pay with any UPI app',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 32),
                    
                    // QR Code Display
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.saffron, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 200,
                          color: AppColors.text1,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      'store@upi',
                      style: AppTextStyles.h4.copyWith(letterSpacing: 1.5, color: AppColors.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.showSnack('QR saved to gallery'),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.showSnack('Opening share dialog...'),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Share QR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
