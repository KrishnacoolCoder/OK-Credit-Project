import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';
import '../../../services/auth_service.dart';
import '../../providers/providers.dart';
import '../../widgets/sangam_logo.dart';

class StaffSignupScreen extends ConsumerStatefulWidget {
  const StaffSignupScreen({super.key});
  @override
  ConsumerState<StaffSignupScreen> createState() => _StaffSignupScreenState();
}

class _StaffSignupScreenState extends ConsumerState<StaffSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _isSignedIn = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      setState(() => _isSignedIn = true);
      context.showSnack('Authenticated! Now enter your invite code.');
    } catch (e) {
      if (!mounted) return;
      context.showSnack('Google Sign-In failed or was cancelled', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitInviteCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      await ref.read(authServiceProvider).redeemInviteCode(
            inviteCode: _codeCtrl.text.trim(),
          );
      await ref.read(currentUserProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/dashboard');
      context.showSnack('Welcome to the team!');
    } on InvalidInviteException catch (e) {
      if (!mounted) return;
      context.showSnack(e.message, isError: true);
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      context.showSnack(e.message ?? 'Could not join shop', isError: true);
    } catch (e) {
      if (!mounted) return;
      context.showSnack('Something went wrong, please try again', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Join your shop'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SangamLogo(size: 80).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
              ),
              const SizedBox(height: 24),
              Text('Create your staff login', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                'First, sign in securely with your Google account. Then, enter the invite code provided by the shop owner.',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: 32),
              
              if (!_isSignedIn) ...[
                // Google Sign In Button
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
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ] else ...[
                // Invite Code Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Signed in with Google.',
                          style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INVITE CODE', style: AppTextStyles.labelCaps),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: AppTextStyles.h3.copyWith(letterSpacing: 4),
                        textAlign: TextAlign.center,
                        validator: (v) => (v == null || v.trim().length < 6) ? 'Enter the 6-character code' : null,
                        decoration: const InputDecoration(hintText: 'ABC123'),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitInviteCode,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Join shop'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
