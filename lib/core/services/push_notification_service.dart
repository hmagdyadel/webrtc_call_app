import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../../app/router/app_router.dart';

import 'package:flutter/foundation.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  _markMessageAsDelivered(message.data);
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
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handlePayloadNavigation(data);
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    _markMessageAsDelivered(message.data);
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body,
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
        'otherUserId': data['senderId'], // Assuming senderId is passed in the payload
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
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }
}
