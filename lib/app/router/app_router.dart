import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/view/screens/otp_screen.dart';
import '../../features/auth/view/screens/phone_screen.dart';
import '../../features/auth/viewmodel/auth_cubit.dart';
import '../../features/auth/viewmodel/auth_state.dart';
import '../../features/chat/view/screens/home_screen.dart';
import '../../features/chat/view/screens/new_chat_screen.dart';
import '../../core/di/injection.dart';

class AppRoutePaths {
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const home = '/home';
  static const newChat = '/home/new-chat';
}

GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutePaths.phone,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState.whenOrNull(authenticated: (_) => true) ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return AppRoutePaths.phone;
      if (isLoggedIn && isAuthRoute) return AppRoutePaths.home;
      return null;
    },
    routes: [
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
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
