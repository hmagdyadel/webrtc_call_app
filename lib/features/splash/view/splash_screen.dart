import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/onboarding_store.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _routeNext);
  }

  void _routeNext() {
    if (!mounted) return;
    final authState = getIt<AuthCubit>().state;
    final isLoggedIn = authState.whenOrNull(authenticated: (_) => true) ?? false;
    final isOnboardingSeen = getIt<OnboardingStore>().isSeen;

    if (!isOnboardingSeen) {
      context.go(AppRoutePaths.onboarding);
      return;
    }
    context.go(isLoggedIn ? AppRoutePaths.home : AppRoutePaths.phone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _SplashLogo(),
            SizedBox(height: 20),
            Text(
              'Botim Clone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chat & Calls',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            top: 30,
            child: Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF2196F3),
              size: 34,
            ),
          ),
          Positioned(
            bottom: 26,
            child: Icon(
              Icons.call_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
