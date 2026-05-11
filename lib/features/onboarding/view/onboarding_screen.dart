import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/onboarding_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      lottie: 'assets/animations/onboarding_chat.json',
      titleAr: 'تواصل مع اللي تحبهم',
      titleEn: 'Chat with those you love',
      subtitle: 'رسائل فورية، صور، وملفات\nكل شيء في مكان واحد',
    ),
    _OnboardingPageData(
      lottie: 'assets/animations/onboarding_voice.json',
      titleAr: 'مكالمات زي ما تكون جنب بعض',
      titleEn: 'Calls that feel face-to-face',
      subtitle: 'جودة صوت عالية بتقنية WebRTC\nمن غير انقطاع',
    ),
    _OnboardingPageData(
      lottie: 'assets/animations/onboarding_video.json',
      titleAr: 'شوف وجه بعض في أي وقت',
      titleEn: 'See each other, anytime',
      subtitle: 'مكالمات فيديو مشفرة تماماً\nخصوصيتك مضمونة',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await getIt<OnboardingStore>().markSeen();
    if (!mounted) return;
    context.go(AppRoutePaths.phone);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'تخطى',
                  style: TextStyle(color: colors.text3, fontSize: 14),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (_, index) => _OnboardingPage(data: _pages[index]),
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: colors.divider,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3.5,
                spacing: 6,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _page < _pages.length - 1 ? 'التالي' : 'ابدأ الآن',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(data.lottie, width: 260, height: 260, repeat: true),
          const SizedBox(height: 36),
          Text(
            data.titleAr,
            style: TextStyle(
              color: context.sawaColors.text1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          Text(
            data.titleEn,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Text(
            data.subtitle,
            style: TextStyle(
              color: context.sawaColors.text2,
              fontSize: 15,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.lottie,
    required this.titleAr,
    required this.titleEn,
    required this.subtitle,
  });

  final String lottie;
  final String titleAr;
  final String titleEn;
  final String subtitle;
}
