import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

@lazySingleton
class PresenceService with WidgetsBindingObserver {
  final AuthRepository _authRepository;
  bool _isInitialized = false;

  PresenceService(this._authRepository);

  void initialize() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _updatePresence(true); // Set online when first initialized
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updatePresence(false);
    }
  }

  Future<void> _updatePresence(bool isOnline) async {
    if (_authRepository.isLoggedIn) {
      await _authRepository.updatePresence(isOnline);
    }
  }
}
