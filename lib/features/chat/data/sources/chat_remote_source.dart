import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteSource {
  Stream<List<ChatModel>> getChats(String userId);
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
}

@LazySingleton(as: ChatRemoteSource)
class ChatRemoteSourceImpl implements ChatRemoteSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ChatModel>> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList());
  }

  @override
  Future<String> createOrGetChat(
      String currentUserId, String otherUserId) async {
    final existing = await _firestore
        .collection('chats')
        .where('members', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final members = List<String>.from(doc.data()['members'] ?? []);
      if (members.contains(otherUserId)) return doc.id;
    }

    final chatRef = await _firestore.collection('chats').add({
      'members': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageSenderId': '',
      'last_message_time': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    });

    return chatRef.id;
  }
}