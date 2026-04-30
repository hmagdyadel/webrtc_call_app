import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../app/router/app_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/onboarding_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      animationPath: 'assets/animations/onboarding_chat.json',
      title: 'Real-time Chat',
      description: 'Send and receive messages instantly with your contacts.',
    ),
    _OnboardingPageData(
      animationPath: 'assets/animations/onboarding_call.json',
      title: 'Crystal Clear Calls',
      description: 'Make smooth voice and video calls powered by WebRTC.',
    ),
    _OnboardingPageData(
      animationPath: 'assets/animations/onboarding_security.json',
      title: 'Private and Secure',
      description: 'Your conversations are protected with secure authentication.',
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
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (_, index) => _OnboardingPage(data: _pages[index]),
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: _pages.length,
                effect: WormEffect(
                  dotColor: Colors.grey.shade700,
                  activeDotColor: const Color(0xFF2196F3),
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isLastPage) {
                      await _completeOnboarding();
                    } else {
                      await _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                  ),
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Lottie.asset(
            data.animationPath,
            repeat: true,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.animationPath,
    required this.title,
    required this.description,
  });

  final String animationPath;
  final String title;
  final String description;
}
