import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

/// Shown once on first install, before sign-in.
/// Marks 'intro_seen' in SharedPreferences when dismissed.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  static const _keyIntroSeen = 'intro_seen';

  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      gradientColors: [Color(0xFFFFE4B5), Color(0xFFFFCC70)],
      iconColor: Color(0xFFE8852A),
      icon: Icons.restaurant_rounded,
      title: 'Discover World Cuisines',
      description:
          'Explore thousands of authentic dishes from cuisines spanning every corner of the globe.',
    ),
    _Slide(
      gradientColors: [Color(0xFFD4EDFF), Color(0xFFA8D8FF)],
      iconColor: Color(0xFF2F74CC),
      icon: Icons.lock_open_rounded,
      title: 'Unlock More Flavours',
      description:
          'Unlock premium cuisines to dive deeper into regional recipes and hidden culinary gems.',
    ),
    _Slide(
      gradientColors: [Color(0xFFFFD6D6), Color(0xFFFFAFAF)],
      iconColor: Color(0xFFE53935),
      icon: Icons.favorite_rounded,
      title: 'Save Your Favourites',
      description:
          'Bookmark the dishes you love and come back to them anytime, even offline.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroSeen, true);
    if (!mounted) return;
    context.go(AppRouter.auth);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Slide pages ──────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _SlidePage(slide: _slides[index]),
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // ── Next / Get Started button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      key: ValueKey(isLast),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide data model ─────────────────────────────────────────────────────────

class _Slide {
  final List<Color> gradientColors;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String description;

  const _Slide({
    required this.gradientColors,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ── Single slide page ────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: slide.gradientColors,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 96,
              color: slide.iconColor,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
