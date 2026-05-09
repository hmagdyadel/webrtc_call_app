import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import '../models/user_model.dart';
import '../sources/auth_remote_source.dart';
import '../sources/user_remote_source.dart';

abstract class AuthRepository {
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  });

  Future<UserModel> verifyOTP({
    required String verificationId,
    required String otp,
  });

  Future<void> signOut();
  bool get isLoggedIn;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUserProfile({
    String? name,
    String? birthdate,
    String? about,
    File? imageFile,
  });
  Future<void> updatePresence(bool isOnline);
}

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _authSource;
  final UserRemoteSource _userSource;

  AuthRepositoryImpl(this._authSource, this._userSource);

  @override
  bool get isLoggedIn => _authSource.currentUser != null;

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authSource.currentUser;
    if (firebaseUser == null) return null;
    return await _userSource.getUser(firebaseUser.uid);
  }

  @override
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _authSource.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  @override
  Future<UserModel> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = await _authSource.verifyOTP(
      verificationId: verificationId,
      otp: otp,
    );

    final firebaseUser = credential.user!;

    // Check if user already exists in Firestore
    final existingUser = await _userSource.getUser(firebaseUser.uid);
    if (existingUser != null) return existingUser;

    // First time — create new user in Firestore
    final newUser = UserModel(
      id: firebaseUser.uid,
      phone: firebaseUser.phoneNumber ?? '',
      name: '',
      isOnline: true,
      createdAt: DateTime.now(),
    );

    await _userSource.saveUser(newUser);
    return newUser;
  }

  @override
  Future<void> signOut() async => await _authSource.signOut();

  @override
  Future<UserModel> updateUserProfile({
    String? name,
    String? birthdate,
    String? about,
    File? imageFile,
  }) async {
    final firebaseUser = _authSource.currentUser;
    if (firebaseUser == null) throw Exception('No user logged in');

    UserModel? currentUser = await _userSource.getUser(firebaseUser.uid);
    if (currentUser == null) throw Exception('User document not found');

    String avatarUrl = currentUser.avatarUrl;

    if (imageFile != null) {
      try {
        final storage = FirebaseStorage.instance;
        final storageRef = storage
            .ref()
            .child('user_avatars')
            .child('${firebaseUser.uid}.jpg');
        
  
        await storageRef.putFile(imageFile);
        avatarUrl = await storageRef.getDownloadURL();
      } catch (e) {
       
        if (e is FirebaseException && e.code == 'not-found') {
          throw Exception('Firebase Storage bucket not found. Please ensure Storage is enabled in the Firebase Console and the bucket name in firebase_options.dart matches.');
        }
        rethrow;
      }
    }

    final updatedUser = currentUser.copyWith(
      name: name ?? currentUser.name,
      birthdate: birthdate ?? currentUser.birthdate,
      about: about ?? currentUser.about,
      avatarUrl: avatarUrl,
    );

    await _userSource.saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> updatePresence(bool isOnline) async {
    final firebaseUser = _authSource.currentUser;
    if (firebaseUser != null) {
      try {
        await _userSource.updatePresence(firebaseUser.uid, isOnline);
      } catch (_) {
        // Ignore presence update errors (e.g. if document doesn't exist yet)
      }
    }
  }
}