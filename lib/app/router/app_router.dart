import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/onboarding_store.dart';
import '../../features/auth/view/screens/otp_screen.dart';
import '../../features/auth/view/screens/phone_screen.dart';
import '../../features/auth/viewmodel/auth_cubit.dart';
import '../../features/auth/viewmodel/auth_state.dart';
import '../../features/chat/view/screens/chat_screen.dart';
import '../../features/chat/view/screens/home_screen.dart';
import '../../features/chat/view/screens/new_chat_screen.dart';
import '../../features/chat/view/screens/my_qr_screen.dart';
import '../../features/chat/view/screens/qr_scanner_screen.dart';
import '../../features/profile/view/screens/profile_screen.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/splash/view/splash_screen.dart';
import '../../core/di/injection.dart';

class AppRoutePaths {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const home = '/home';
  static const newChat = '/home/new-chat';
  static const chatDetail = '/home/chat/:chatId';
  static const myQr = '/home/qr-my';
  static const qrScanner = '/home/qr-scanner';
  static const profile = '/home/profile';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthCubit authCubit, OnboardingStore onboardingStore) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    refreshListenable: GoRouterRefresh(authCubit.stream, onboardingStore),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState.whenOrNull(authenticated: (_) => true) ?? false;
      final isSplashRoute = state.matchedLocation == AppRoutePaths.splash;
      final isOnboardingRoute = state.matchedLocation == AppRoutePaths.onboarding;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingSeen = onboardingStore.isSeen;

      if (isSplashRoute) return null;

      if (!isOnboardingSeen && !isOnboardingRoute) {
        return AppRoutePaths.onboarding;
      }
      if (isOnboardingSeen && isOnboardingRoute) {
        return isLoggedIn ? AppRoutePaths.home : AppRoutePaths.phone;
      }
      if (isOnboardingRoute) return null;

      if (!isLoggedIn && !isAuthRoute) return AppRoutePaths.phone;
      if (isLoggedIn && isAuthRoute) return AppRoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.phone,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.otp,
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          if (phoneNumber == null || phoneNumber.isEmpty) {
            return const PhoneScreen();
          }
          return OtpScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: AppRoutePaths.home,
        builder: (context, state) {
          final authState = getIt<AuthCubit>().state;
          final userId = authState.whenOrNull(authenticated: (user) => user.id) ?? '';
          return HomeScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutePaths.newChat,
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.chatDetail,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final authState = getIt<AuthCubit>().state;
          final currentUserId = authState.whenOrNull(authenticated: (user) => user.id) ?? '';
          final otherUserId = extra['otherUserId']?.toString() ?? '';
          return ChatScreen(
            chatId: chatId,
            currentUserId: currentUserId,
            otherUserId: otherUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.myQr,
        builder: (context, state) => const MyQRScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.qrScanner,
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}

class GoRouterRefresh extends ChangeNotifier {
  GoRouterRefresh(Stream<dynamic> stream, OnboardingStore onboardingStore) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
    onboardingStore.addListener(notifyListeners);
    _onboardingStore = onboardingStore;
  }

  late final StreamSubscription<dynamic> _subscription;
  late final OnboardingStore _onboardingStore;

  @override
  void dispose() {
    _onboardingStore.removeListener(notifyListeners);
    _subscription.cancel();
    super.dispose();
  }
}
