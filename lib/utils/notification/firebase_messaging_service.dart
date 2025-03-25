import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/notification/awsome_notification.dart';
import 'package:tlobni/utils/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalAwesomeNotification _localNotification =
      LocalAwesomeNotification();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Get permission for iOS
    if (Platform.isIOS) {
      await _requestPermission();
    }

    // Get FCM token
    await getToken();

    // Configure message handling
    _configureMessageHandling();
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> getToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Store token in secure storage if user is authenticated
    if (HiveUtils.isUserAuthenticated() && _fcmToken != null) {
      HiveUtils.setFcmToken(_fcmToken!);
    }

    // Subscribe to topics
    await _firebaseMessaging.subscribeToTopic('all');

    // Setup token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $_fcmToken');

      if (HiveUtils.isUserAuthenticated()) {
        HiveUtils.setFcmToken(newToken);
        _updateTokenOnServer(newToken);
      }
    });
  }

  Future<void> _updateTokenOnServer(String token) async {
    // Implement this method to update the token on your server
    if (!HiveUtils.isUserAuthenticated()) return;

    try {
      final userId = HiveUtils.getUserId();
      final apiUrl = '${Constant.baseUrl}/update-fcm-token';

      await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${HiveUtils.getJwtToken()}',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      debugPrint('FCM token updated on server');
    } catch (e) {
      debugPrint('Error updating FCM token on server: $e');
    }
  }

  void _configureMessageHandling() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');
      }

      NotificationService.handleNotification(message, false);
    });

    // Handle messages when app is in background and user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked (background): ${message.data}');
      NotificationService.handleNotification(message, false);
    });

    // Check if app was opened from a notification
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Initial message: ${message.data}');
        Future.delayed(const Duration(seconds: 1), () {
          NotificationService.handleNotification(message, true);
        });
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Register with topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unregister from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}

// This function is called when a background message is received
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handling if needed
  await Firebase.initializeApp();

  debugPrint('Handling a background message: ${message.messageId}');

  NotificationService.handleNotification(message, true);
}
