import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../app/router/app_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/onboarding_store.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/viewmodel/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _lottieController;
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _timer = Timer(const Duration(milliseconds: 2400), () {
      _timerFinished = true;
      _routeNext();
    });
  }

  void _routeNext() {
    if (!mounted || !_timerFinished) return;
    
    final authState = getIt<AuthCubit>().state;
    
    final isDetermined = authState.maybeWhen(
      initial: () => false,
      loading: () => false,
      orElse: () => true,
    );
    
    if (!isDetermined) return;

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
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    return BlocListener<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      listener: (context, state) {
        _routeNext();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Lottie.asset(
                'assets/animations/splash.json',
                controller: _lottieController,
                width: 180,
                height: 180,
                onLoaded: (composition) {
                  _lottieController
                    ..duration = composition.duration
                    ..forward();
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'سوا',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'SAWA',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 8,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Text(
                  'سوا دايماً متواصلين',
                  style: TextStyle(
                    color: colors.text3,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
