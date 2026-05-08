import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteSource {
  Stream<List<ChatModel>> getChats(String userId);
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, MessageModel message);
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

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList());
  }

  @override
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);
    batch.set(msgRef, {
      'senderId': message.senderId,
      'text': message.text,
      'type': message.type,
      'timestamp': FieldValue.serverTimestamp(),
      'status': message.status,
    });

    // Update chat metadata
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': message.text,
      'lastMessageSenderId': message.senderId,
      'last_message_time': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}