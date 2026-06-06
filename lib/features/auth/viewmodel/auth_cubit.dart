import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  String? _verificationId;

  AuthCubit(this._repository) : super(const AuthState.initial());

  Future<void> checkAuthStatus() async {
    emit(const AuthState.loading());
    try {
      if (_repository.isLoggedIn) {
        final user = await _repository.getCurrentUser();
        if (user != null) {
          emit(AuthState.authenticated(user: user));
        } else {
          // User is logged in Firebase but no Firestore doc exists.
          // This may also happen due to a transient permission error during
          // first launch. Do NOT sign out — let them stay on the home screen
          // and the Firestore rules will handle authorization from there.
          // Only sign out if Firebase Auth itself says the user is gone.
          if (!_repository.isLoggedIn) {
            emit(const AuthState.unauthenticated());
          } else {
            // Firestore doc missing but auth token is valid — sign out cleanly
            await _repository.signOut();
            emit(const AuthState.unauthenticated());
          }
        }
      } else {
        emit(const AuthState.unauthenticated());
      }
    } on Exception catch (e) {
      // A Firestore permission error or network error must NOT sign the user out.
      // Keep them authenticated if Firebase Auth still considers them logged in.
      if (_repository.isLoggedIn) {
        // Try to emit authenticated with a fallback minimal user from Firebase Auth
        debugPrint('Warning: checkAuthStatus error, keeping user logged in: $e');
        // Re-emit the current state to avoid getting stuck in loading
        final user = await _repository.getCurrentUser().catchError((_) => null);
        if (user != null) {
          emit(AuthState.authenticated(user: user));
        }
        // If still can't get user, stay in loading to prevent redirect loop
      } else {
        await _repository.signOut();
        emit(const AuthState.unauthenticated());
      }
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    emit(const AuthState.loading());
    await _repository.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        Future.microtask(() => emit(const AuthState.otpSent()));
      },
      onError: (error) {
        Future.microtask(() => emit(AuthState.error(message: error)));
      },
    );
  }

  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) return;
    emit(const AuthState.loading());
    try {
      final user = await _repository.verifyOTP(
        verificationId: _verificationId!,
        otp: otp,
      );
      emit(AuthState.authenticated(user: user));
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> sendOTPWithCallback({
    required String phoneNumber,
    required Function() onCodeSent,
    required Function(String) onError,
  }) async {
    emit(const AuthState.sendingOtp()); // ← not loading
    await _repository.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        emit(const AuthState.otpSent());
        onCodeSent();
      },
      onError: (error) {
        emit(AuthState.error(message: error));
        onError(error);
      },
    );
  }
  Future<void> signOut() async {
    await _repository.signOut();
    emit(const AuthState.unauthenticated());
  }

  Future<void> updateProfile({
    String? name,
    String? birthdate,
    String? about,
    File? imageFile,
  }) async {
    try {
      final updatedUser = await _repository.updateUserProfile(
        name: name,
        birthdate: birthdate,
        about: about,
        imageFile: imageFile,
      );
      emit(AuthState.authenticated(user: updatedUser));
    } catch (e) {
      // Could emit an error state or handle it via a callback
      rethrow;
    }
  }
}