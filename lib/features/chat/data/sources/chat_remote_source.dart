import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteSource {
  Stream<List<ChatModel>> getChats(String userId);
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, MessageModel message);
  Future<void> markChatAsRead(String chatId, String currentUserId);
  Future<String> uploadMedia(String filePath, String storagePath, {Function(double)? onProgress});
}

@LazySingleton(as: ChatRemoteSource)
class ChatRemoteSourceImpl implements ChatRemoteSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // We need to import firebase_storage in the file, but we will use FirebaseStorage.instance directly.
  
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
        
    final messageData = {
      'senderId': message.senderId,
      'text': message.text,
      'type': message.type,
      'timestamp': FieldValue.serverTimestamp(),
      'status': message.status,
    };
    
    if (message.mediaUrl != null) {
      messageData['mediaUrl'] = message.mediaUrl!;
    }
    if (message.metadata != null) {
      messageData['metadata'] = message.metadata!;
    }

    batch.set(msgRef, messageData);

    // Update chat metadata
    String lastMessageText = message.text;
    if (message.type == 'image') lastMessageText = '📷 Image';
    if (message.type == 'video') lastMessageText = '🎥 Video';
    if (message.type == 'file') lastMessageText = '📄 Document';
    if (message.type == 'location') lastMessageText = '📍 Location';
    if (message.type == 'sticker') lastMessageText = '✨ Sticker';

    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': lastMessageText,
      'lastMessageSenderId': message.senderId,
      'last_message_time': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    final batch = _firestore.batch();

    // Reset unread count
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {'unreadCount': 0});

    // Find all messages from the other user that are not 'read'
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (var doc in unreadMessages.docs) {
      if (doc.data()['status'] != 'read') {
        batch.update(doc.reference, {'status': 'read'});
      }
    }

    await batch.commit();
  }

  @override
  Future<String> uploadMedia(String filePath, String storagePath, {Function(double)? onProgress}) async {
    final file = File(filePath);
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    final uploadTask = ref.putFile(file);
    
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}