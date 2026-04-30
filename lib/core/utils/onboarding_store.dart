import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class OnboardingStore extends ChangeNotifier {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  bool get isSeen => _prefs.getBool(AppConstants.onboardingSeenKey) ?? false;

  Future<void> markSeen() async {
    await _prefs.setBool(AppConstants.onboardingSeenKey, true);
    notifyListeners();
  }
}
