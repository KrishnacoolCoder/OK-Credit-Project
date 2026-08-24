import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../providers/providers.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('Help & Support', 'सहायता', hi)),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.saffron,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.saffron,
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  tr('How can we help you?', 'हम आपकी कैसे मदद कर सकते हैं?', hi),
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  tr('Find answers below or contact us directly', 'नीचे उत्तर ढूंढें या सीधे संपर्क करें', hi),
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // Contact Options
          Text(tr('CONTACT US', 'हमसे संपर्क करें', hi), style: AppTextStyles.labelCaps),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: Icons.email_outlined,
                  label: tr('Email', 'ईमेल', hi),
                  subtitle: 'support@sangam.app',
                  color: const Color(0xFF1976D2),
                  onTap: () => _launchUrl('mailto:support@sangam.app?subject=Sangam%20Pro%20Help'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  icon: Icons.chat_rounded,
                  label: tr('WhatsApp', 'व्हाट्सएप्प', hi),
                  subtitle: tr('Chat with us', 'चैट करें', hi),
                  color: const Color(0xFF25D366),
                  onTap: () => _launchUrl('https://wa.me/919876543210?text=Hi%20Sangam%20Support'),
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // FAQ Section
          Text(tr('FREQUENTLY ASKED QUESTIONS', 'अक्सर पूछे जाने वाले प्रश्न', hi), style: AppTextStyles.labelCaps),
          const SizedBox(height: 12),
          _FaqItem(
            question: tr('How do I add a new customer?', 'नया ग्राहक कैसे जोड़ें?', hi),
            answer: tr(
              'Go to the Ledger tab → Tap the "+" button at the bottom → Enter the customer\'s name and phone number → Tap "Add Customer".',
              'लेजर टैब पर जाएं → नीचे "+" बटन टैप करें → ग्राहक का नाम और फ़ोन नंबर दर्ज करें → "ग्राहक जोड़ें" टैप करें।',
              hi,
            ),
          ),
          _FaqItem(
            question: tr('How do I record credit (Udhar)?', 'उधार कैसे दर्ज करें?', hi),
            answer: tr(
              'Open a customer → Tap "You Gave (Credit)" → Enter amount, optional note, and date → Tap Save. The balance updates automatically.',
              'ग्राहक खोलें → "आपने दिया (उधार)" टैप करें → राशि, नोट और तारीख दर्ज करें → सेव करें। बैलेंस अपने आप अपडेट हो जाएगा।',
              hi,
            ),
          ),
          _FaqItem(
            question: tr('How do I add staff to my shop?', 'अपनी दुकान में स्टाफ कैसे जोड़ें?', hi),
            answer: tr(
              'Go to Settings → Team & Staff → Tap "Add Staff" → Enter the staff member\'s name → Share the generated 6-digit invite code with them. They install the app, sign in with Google, and enter the code.',
              'सेटिंग्स → टीम और स्टाफ → "स्टाफ जोड़ें" टैप करें → नाम दर्ज करें → 6 अंकों का कोड शेयर करें। वे ऐप इंस्टॉल करें, Google से साइन इन करें, और कोड दर्ज करें।',
              hi,
            ),
          ),
          _FaqItem(
            question: tr('Is my data safe?', 'क्या मेरा डेटा सुरक्षित है?', hi),
            answer: tr(
              'Yes! Your data is encrypted and synced to Google Cloud (Firebase). Only you and your authorized staff can access it. We never share your data with anyone.',
              'हाँ! आपका डेटा एन्क्रिप्टेड है और Google Cloud (Firebase) पर सिंक होता है। केवल आप और आपके अधिकृत स्टाफ ही इसे एक्सेस कर सकते हैं।',
              hi,
            ),
          ),
          _FaqItem(
            question: tr('How does multi-device sync work?', 'मल्टी-डिवाइस सिंक कैसे काम करता है?', hi),
            answer: tr(
              'Sign in with the same Google account on any device and you\'ll see the same live data. For staff, generate an invite code from Settings → Team. Changes sync in real-time across all devices.',
              'किसी भी डिवाइस पर उसी Google खाते से साइन इन करें और आप वही लाइव डेटा देखेंगे। स्टाफ के लिए, सेटिंग्स → टीम से इनवाइट कोड बनाएं।',
              hi,
            ),
          ),
          _FaqItem(
            question: tr('How do I send payment reminders?', 'भुगतान रिमाइंडर कैसे भेजें?', hi),
            answer: tr(
              'Open a customer → Tap "Remind" to send a WhatsApp reminder with outstanding balance. For bulk reminders, use the Auto Reminder feature from the More menu.',
              'ग्राहक खोलें → बकाया राशि का WhatsApp रिमाइंडर भेजने के लिए "रिमाइंड" टैप करें। बल्क रिमाइंडर के लिए, More मेनू से ऑटो रिमाइंडर का उपयोग करें।',
              hi,
            ),
          ),
          const SizedBox(height: 24),

          // App Info
          Center(
            child: Column(
              children: [
                Text('Sangam Pro v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                const SizedBox(height: 4),
                Text(
                  tr('Made with ❤ in India', 'भारत में ❤ से बनाया', hi),
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.text3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _expanded ? AppColors.saffron.withValues(alpha: 0.3) : AppColors.borderLight),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: _expanded ? FontWeight.w600 : FontWeight.w500,
                          color: _expanded ? AppColors.saffron : AppColors.text1,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded ? AppColors.saffron : AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(widget.answer, style: AppTextStyles.body.copyWith(color: AppColors.text2, height: 1.5)),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
