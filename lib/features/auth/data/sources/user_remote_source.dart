import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/user_model.dart';

abstract class UserRemoteSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String uid);
  Future<bool> userExists(String uid);
  Future<void> updatePresence(String uid, bool isOnline);
}

@LazySingleton(as: UserRemoteSource)
class UserRemoteSourceImpl implements UserRemoteSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'users';

  @override
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(_collection)
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> updatePresence(String uid, bool isOnline) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isOnline': isOnline,
      'last_seen': FieldValue.serverTimestamp(),
    });
  }
}