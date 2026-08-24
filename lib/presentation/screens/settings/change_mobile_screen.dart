import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';

class ChangeMobileScreen extends ConsumerStatefulWidget {
  const ChangeMobileScreen({super.key});

  @override
  ConsumerState<ChangeMobileScreen> createState() => _ChangeMobileScreenState();
}

class _ChangeMobileScreenState extends ConsumerState<ChangeMobileScreen> {
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_phoneCtrl.text.length < 10) {
      context.showSnack('Enter a valid 10-digit mobile number', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);
    if (!mounted) return;
    
    _showOtpSheet();
  }

  void _showOtpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.saffronLight, shape: BoxShape.circle),
              child: const Icon(Icons.message_outlined, color: AppColors.saffron, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Enter OTP', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('Sent to +91 ${_phoneCtrl.text}', style: AppTextStyles.body),
            const SizedBox(height: 32),
            PinCodeTextField(
              appContext: ctx,
              length: 4,
              keyboardType: TextInputType.number,
              animationType: AnimationType.scale,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 56,
                fieldWidth: 56,
                activeFillColor: AppColors.surface,
                inactiveFillColor: AppColors.background,
                selectedFillColor: AppColors.saffronLight,
                activeColor: AppColors.saffron,
                inactiveColor: AppColors.border,
                selectedColor: AppColors.saffron,
              ),
              enableActiveFill: true,
              onChanged: (v) {},
              onCompleted: (v) async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 600));
                if (mounted) {
                  setState(() => _isLoading = false);
                  context.showSnack('Mobile number updated successfully!');
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Mobile Number'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.phonelink_setup_rounded, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('New Mobile Number', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('We will send a 4-digit OTP to verify this number.', style: AppTextStyles.body),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: AppTextStyles.h3,
              decoration: const InputDecoration(
                prefixText: '+91  ',
                hintText: 'Enter 10 digit number',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify with OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
