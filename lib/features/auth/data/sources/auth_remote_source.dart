import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class AuthRemoteSource {
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  });

  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  });

  Future<void> signOut();
  User? get currentUser;
}

@LazySingleton(as: AuthRemoteSource)
class AuthRemoteSourceImpl implements AuthRemoteSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    print('=== sendOTP called with: $phoneNumber ===');
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('=== verificationCompleted ===');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('=== verificationFailed: ${e.code} | ${e.message} ===');
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('=== codeSent successfully ===');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('=== codeAutoRetrievalTimeout ===');
          // Only navigate if we haven't already
          onCodeSent(verificationId);
        },
      );
    } catch (e) {
      print('=== sendOTP exception: $e ===');
      onError(e.toString());
    }
  }

  @override
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async => await _auth.signOut();
}