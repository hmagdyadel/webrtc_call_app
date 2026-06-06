import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../../app/router/app_router.dart';

import 'package:flutter/foundation.dart';

// Top-level function for background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase already initialized or error: $e');
  }
  _markMessageAsDelivered(message.data);

  final title = message.notification?.title ?? message.data['title'] ?? 'New Message';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  final androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    channelDescription: 'Notifications for incoming chat messages',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(body),
    actions: <AndroidNotificationAction>[
      // Reply: opens the app and navigates to chat
      const AndroidNotificationAction(
        'reply',
        'Reply',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      // Mark as Read: opens app briefly to ensure reliable execution
      const AndroidNotificationAction(
        'mark_read',
        'Mark as Read',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
  );

  final details = NotificationDetails(android: androidDetails);
  await FlutterLocalNotificationsPlugin().show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: details,
    payload: jsonEncode(message.data),
  );
}

/// Background handler for notification actions.
/// Now works because ActionBroadcastReceiver is registered in AndroidManifest.xml.
@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) async {
  debugPrint('Background notification action received: ${response.actionId}');

  if (response.payload == null) return;

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase already initialized or error: $e');
  }

  final data = jsonDecode(response.payload!);
  final chatId = data['chatId'];
  final currentUserId = data['receiverId'];

  if (response.actionId == 'mark_read') {
    if (chatId != null && currentUserId != null) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
        batch.update(chatRef, {'unreadCount': 0});

        final unreadMsgs = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId)
            .get();

        for (var doc in unreadMsgs.docs) {
          if (doc.data()['status'] != 'read') {
            batch.update(doc.reference, {'status': 'read'});
          }
        }
        await batch.commit();
        debugPrint('✅ Marked chat $chatId as read');
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }
  // Reply action uses showsUserInterface: true, so it's handled
  // by the foreground onDidReceiveNotificationResponse callback.
}

Future<void> _markMessageAsDelivered(Map<String, dynamic> data) async {
  try {
    final chatId = data['chatId'];
    final messageId = data['messageId'];

    if (chatId != null && messageId != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': 'delivered'});
      debugPrint('Marked message $messageId as delivered');
    }
  } catch (e) {
    debugPrint('Error marking message as delivered: $e');
  }
}

@lazySingleton
class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request permissions
    await _requestPermissions();

    // 2. Initialize local notifications for foreground display
    await _initLocalNotifications();

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification taps (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Handle notification taps (app was terminated)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Get and save the FCM token
    await _saveFCMToken();

    // 8. Listen to token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Foreground notification action: ${response.actionId}');

        if (response.payload == null) return;
        final data = jsonDecode(response.payload!);

        if (response.actionId == 'reply') {
          // Reply: navigate to the chat screen
          _handlePayloadNavigation(data);
        } else if (response.actionId == 'mark_read') {
          // Mark as Read while app is in foreground
          _markChatAsRead(data);
          if (response.id != null) {
            _localNotifications.cancel(id: response.id!);
          }
        } else {
          // User tapped the notification body → open chat
          _handlePayloadNavigation(data);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );
  }

  /// Marks all messages in a chat as read.
  Future<void> _markChatAsRead(Map<String, dynamic> data) async {
    final chatId = data['chatId'];
    final currentUserId = data['receiverId'] ?? FirebaseAuth.instance.currentUser?.uid;

    if (chatId == null || currentUserId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      batch.update(chatRef, {'unreadCount': 0});

      final unreadMsgs = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      for (var doc in unreadMsgs.docs) {
        if (doc.data()['status'] != 'read') {
          batch.update(doc.reference, {'status': 'read'});
        }
      }
      await batch.commit();
      debugPrint('✅ Marked chat $chatId as read (foreground)');
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    _markMessageAsDelivered(message.data);
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Message';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'reply',
          'Reply',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handlePayloadNavigation(message.data);
  }

  void _handlePayloadNavigation(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    if (chatId != null && rootNavigatorKey.currentContext != null) {
      rootNavigatorKey.currentContext!.push('/home/chat/$chatId', extra: {
        'otherUserId': data['senderId'],
      });
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Use set+merge so this works even if the user document doesn't exist yet
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      // Log but don't rethrow — a failed FCM token save must never trigger sign-out
      debugPrint('Warning: Could not save FCM token to Firestore: $e');
    }
  }
}
