import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ContactsRemoteSource {
  Future<List<UserModel>> getAllUsers(String currentUserId);
  Future<UserModel?> getUserByPhone(String phone);
}

@LazySingleton(as: ContactsRemoteSource)
class ContactsRemoteSourceImpl implements ContactsRemoteSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<UserModel>> getAllUsers(String currentUserId) async {
    final snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<UserModel?> getUserByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return UserModel.fromJson({...doc.data(), 'id': doc.id});
  }
}