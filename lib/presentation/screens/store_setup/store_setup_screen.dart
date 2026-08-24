import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/context_extensions.dart';
import '../../../domain/entities/store_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/sangam_logo.dart';

/// Where a brand-new owner sets up their shop after phone OTP verification.
/// The user is already authenticated — we just need shop details.
class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key});
  @override
  ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      final auth = ref.read(authServiceProvider);
      await auth.createShop(
        shopName: _nameCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );
      await ref.read(currentUserProvider.notifier).refresh();

      await ref.read(storeProfileProvider.notifier).save(
            StoreProfile(
              name: _nameCtrl.text.trim(),
              ownerName: _ownerCtrl.text.trim(),
              location: _locationCtrl.text.trim(),
            ),
          );

      final source = ref.read(localSourceProvider);
      await source.startFresh();

      ref.invalidate(transactionsStreamProvider);
      ref.invalidate(customersStreamProvider);
      ref.invalidate(todayTotalsProvider);
      ref.invalidate(overdueCustomersProvider);
      ref.invalidate(usersProvider);

      if (mounted) {
        context.go('/permissions');
        context.showSnack('Your shop is ready!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('Could not finish setup, try again', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Form(
            key: _formKey,
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
                Text(
                  tr('Set up your shop', 'अपनी दुकान सेट करें', hi),
                  style: AppTextStyles.h1,
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  tr(
                    'Just a few details to get started. You can always edit these later from Settings.',
                    'शुरू करने के लिए बस कुछ जानकारी। इन्हें बाद में सेटिंग्स से बदला जा सकता है।',
                    hi,
                  ),
                  style: AppTextStyles.body,
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 28),

                // ── Shop Name ──
                _label(tr('SHOP NAME', 'दुकान का नाम', hi)),
                _field(
                  _nameCtrl,
                  tr('e.g. Sharma General Store', 'जैसे शर्मा जनरल स्टोर', hi),
                  cap: TextCapitalization.words,
                  icon: Icons.store_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? tr('Enter your shop name', 'दुकान का नाम भरें', hi) : null,
                ),

                // ── Owner Name ──
                _label(tr('YOUR NAME', 'आपका नाम', hi)),
                _field(
                  _ownerCtrl,
                  tr('e.g. Smriti Sharma', 'जैसे स्मृति शर्मा', hi),
                  cap: TextCapitalization.words,
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? tr('Enter your name', 'अपना नाम भरें', hi) : null,
                ),

                // ── Location ──
                _label(tr('LOCATION (optional)', 'स्थान (वैकल्पिक)', hi)),
                _field(
                  _locationCtrl,
                  tr('e.g. Patna, Bihar', 'जैसे पटना, बिहार', hi),
                  cap: TextCapitalization.words,
                  icon: Icons.location_on_outlined,
                  formatters: [LengthLimitingTextInputFormatter(60)],
                ),

                const SizedBox(height: 24),

                // ── Info card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 0.6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(
                            'Your phone number is already verified. This creates your shop profile. Staff can be added later.',
                            'आपका फ़ोन नंबर पहले से सत्यापित है। यह आपकी दुकान प्रोफ़ाइल बनाएगा। स्टाफ बाद में जोड़ा जा सकता है।',
                            hi,
                          ),
                          style: AppTextStyles.caption.copyWith(color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ── Create button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.saffron.withOpacity(0.3),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            tr('Create shop & start', 'दुकान बनाएँ और शुरू करें', hi),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ).animate(delay: 460.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 14),
                Center(
                  child: Text(
                    tr(
                      'No sample or demo data will be added.',
                      'कोई नमूना या डेमो डेटा नहीं जोड़ा जाएगा।',
                      hi,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: AppTextStyles.labelCaps),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextCapitalization cap = TextCapitalization.none,
    bool autocorrect = true,
    IconData? icon,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      textCapitalization: cap,
      autocorrect: autocorrect,
      textInputAction: TextInputAction.next,
      inputFormatters: formatters,
      validator: validator,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }
}
