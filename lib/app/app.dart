import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../core/di/injection.dart';
import '../core/utils/onboarding_store.dart';
import '../core/services/presence_service.dart';
import '../core/theme/theme_cubit.dart';
import '../features/auth/viewmodel/auth_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => getIt<ThemeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final authCubit = context.read<AuthCubit>();
          final onboardingStore = getIt<OnboardingStore>();
          
          // Initialize presence tracking
          getIt<PresenceService>().initialize();

          final router = createAppRouter(authCubit, onboardingStore);

          return MaterialApp.router(
            title: 'Sawa',
            debugShowCheckedModeBanner: false,

            // Both themes registered
            theme: sawaLightTheme(),
            darkTheme: sawaDarkTheme(),

            // System = device default on first install
            // Dark/Light = user's saved override
            themeMode: themeMode,

            builder: EasyLoading.init(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
