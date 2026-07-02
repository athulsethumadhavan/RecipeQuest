import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportEmail = 'athulsethumadhavan+recipeSupport@gmail.com';

  static const _deleteAccountUrl =
      'https://athulsethumadhavan.github.io/RecipeQuest/delete-account';

  // (q, a, btnLabel?, btnUrl?)
  static const _faqs = [
    (
      q: 'How do I unlock a dish?',
      a: 'Tap on any locked dish and select "Unlock Dish" for \$1. '
          'The dish will be permanently unlocked on your account.',
      btn: '',
      url: '',
    ),
    (
      q: 'How do I unlock an entire cuisine?',
      a: 'Open the cuisine page and tap "Unlock All Dishes" for \$10. '
          'This gives you permanent access to every dish in that cuisine.',
      btn: '',
      url: '',
    ),
    (
      q: 'Can I watch videos for free?',
      a: 'Yes! Tap "Watch Ad" on any locked video to watch a short rewarded '
          'ad and get free access to that video for the session.',
      btn: '',
      url: '',
    ),
    (
      q: 'How do I save a dish to Favourites?',
      a: 'Tap the heart icon on any dish card or detail page. '
          'You need to be signed in for your favourites to sync across devices.',
      btn: '',
      url: '',
    ),
    (
      q: 'Will my purchases carry over if I reinstall?',
      a: 'Yes. Sign in with the same account and your unlocked dishes and '
          'cuisines will be restored automatically.',
      btn: '',
      url: '',
    ),
    (
      q: 'I lost my purchases after reinstalling. What do I do?',
      a: 'Sign in with your original account. If the issue persists, '
          'tap "Restore Purchases" in the Subscription section of the side menu.',
      btn: '',
      url: '',
    ),
    (
      q: 'How do I change my password?',
      a: 'On the Sign In screen, tap "Forgot Password?" and follow the '
          'OTP verification steps to set a new password.',
      btn: '',
      url: '',
    ),
    (
      q: 'How do I delete my account?',
      a: 'Submit a deletion request using the form below. Your account and '
          'all associated data will be permanently deleted within 7 business days.',
      btn: 'Request Account Deletion',
      url: _deleteAccountUrl,
    ),
    (
      q: 'Which languages are the cooking videos available in?',
      a: 'Videos are available in English, Hindi, Tamil, Malayalam, Arabic, '
          'German, French, Spanish, Italian, and Chinese.',
      btn: '',
      url: '',
    ),
    (
      q: 'The video isn\'t playing. What should I do?',
      a: 'Check your internet connection. If the problem continues, '
          'the video will open in YouTube automatically as a fallback.',
      btn: '',
      url: '',
    ),
  ];

  int? _expanded;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Recipe Quest Support',
        'body': 'Hi,\n\nI need help with...\n\n'
            '--- App Info ---\nApp: Recipe Quest\n',
      },
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Header card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We\'re here to help!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse FAQs below or contact our support team.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── FAQ section ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final isOpen = _expanded == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOpen ? AppColors.primary : AppColors.divider,
                  width: isOpen ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    setState(() => _expanded = isOpen ? null : i),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.q,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isOpen
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isOpen
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faq.a,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              if (faq.url.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openUrl(faq.url),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    label: Text(faq.btn),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Contact us ───────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Still need help?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.email_outlined,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 10),
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Our team typically responds within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _supportEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _contactSupport,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send Email',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
