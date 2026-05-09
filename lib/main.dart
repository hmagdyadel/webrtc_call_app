import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/utils/onboarding_store.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  await configureDependencies();
  final prefs = await SharedPreferences.getInstance();
  if (!getIt.isRegistered<OnboardingStore>()) {
    getIt.registerSingleton<OnboardingStore>(OnboardingStore(prefs));
  }
  
  // Initialize Push Notifications
  await getIt<PushNotificationService>().init();

  _configureEasyLoading();
  runApp(const App());
}

void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..backgroundColor = const Color(0xFF22223A)
    ..indicatorColor = const Color(0xFF5B4FD4)
    ..textColor = Colors.white
    ..maskColor = Colors.black.withValues(alpha: 0.4)
    ..userInteractions = false
    ..dismissOnTap = false
    ..maskType = EasyLoadingMaskType.black;
}