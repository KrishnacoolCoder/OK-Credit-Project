import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';

class _LangOption {
  final String nativeLabel;
  final String englishLabel;
  final Color bgColor;
  final Color textColor;
  final bool isHindi; // true => sets languageProvider to Hindi mode

  const _LangOption({
    required this.nativeLabel,
    required this.englishLabel,
    required this.bgColor,
    required this.textColor,
    required this.isHindi,
  });
}

const _languages = [
  _LangOption(nativeLabel: 'English',    englishLabel: 'English',           bgColor: Color(0xFFE8F5E9), textColor: Color(0xFF2E7D32), isHindi: false),
  _LangOption(nativeLabel: 'हिंदी',       englishLabel: 'Hindi',             bgColor: Color(0xFFFCE4EC), textColor: Color(0xFFC62828), isHindi: true),
  _LangOption(nativeLabel: 'मराठी',       englishLabel: 'Marathi',           bgColor: Color(0xFFE3F2FD), textColor: Color(0xFF1565C0), isHindi: true),
  _LangOption(nativeLabel: 'Hinglish',   englishLabel: 'Hindi in English',  bgColor: Color(0xFFF3E5F5), textColor: Color(0xFF6A1B9A), isHindi: true),
  _LangOption(nativeLabel: 'ગુજરાતી',    englishLabel: 'Gujarati',          bgColor: Color(0xFFE8F5E9), textColor: Color(0xFF2E7D32), isHindi: true),
  _LangOption(nativeLabel: 'தமிழ்',       englishLabel: 'Tamil',             bgColor: Color(0xFFFFF9C4), textColor: Color(0xFFF57F17), isHindi: true),
  _LangOption(nativeLabel: 'తెలుగు',      englishLabel: 'Telugu',            bgColor: Color(0xFFE0F7FA), textColor: Color(0xFF00838F), isHindi: true),
  _LangOption(nativeLabel: 'ਪੰਜਾਬੀ',      englishLabel: 'Punjabi',           bgColor: Color(0xFFFFF3E0), textColor: Color(0xFFE65100), isHindi: true),
  _LangOption(nativeLabel: 'മലയാളം',     englishLabel: 'Malayalam',         bgColor: Color(0xFFF3E5F5), textColor: Color(0xFF7B1FA2), isHindi: true),
  _LangOption(nativeLabel: 'ಕನ್ನಡ',       englishLabel: 'Kannada',           bgColor: Color(0xFFF5F5F5), textColor: Color(0xFF424242), isHindi: true),
  _LangOption(nativeLabel: 'বাংলা',       englishLabel: 'Bangla',            bgColor: Color(0xFFFFEBEE), textColor: Color(0xFFC62828), isHindi: true),
];

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});
  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  int _selectedIndex = 0;

  Future<void> _continue() async {
    HapticFeedback.mediumImpact();
    final lang = _languages[_selectedIndex];
    ref.read(languageProvider.notifier).state = lang.isHindi;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sangam_language_selected', true);
    await prefs.setBool('sangam_is_hindi', lang.isHindi);

    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            children: [
              Text(
                'Select your Language',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: lang.bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: lang.bgColor.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.nativeLabel,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: lang.textColor,
                                    ),
                                  ),
                                  if (lang.nativeLabel != lang.englishLabel) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      lang.englishLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: lang.textColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: 80 + index * 50))
                        .fadeIn(duration: 350.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
