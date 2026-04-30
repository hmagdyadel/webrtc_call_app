import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../core/di/injection.dart';
import '../core/utils/onboarding_store.dart';
import '../features/auth/viewmodel/auth_cubit.dart';
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
      child: Builder(
        builder: (context) {
          final authCubit = context.read<AuthCubit>();
          final onboardingStore = getIt<OnboardingStore>();
          final router = createAppRouter(authCubit, onboardingStore);

          return MaterialApp.router(
            title: 'Call App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
            ),
            builder: EasyLoading.init(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
