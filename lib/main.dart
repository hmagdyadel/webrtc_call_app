import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/utils/onboarding_store.dart';
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
  runApp(const App());
}