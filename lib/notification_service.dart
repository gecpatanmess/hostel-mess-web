import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'badge_helper.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM Token
        String? token = await _messaging.getToken();
        print("FCM Token: $token");
        
        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Got a message whilst in the foreground!');

          if (message.notification != null) {
            print('Notification Title: ${message.notification?.title}');
          }

          if (kIsWeb) {
            setAppBadgeHelper(1);
          }
        });
      }
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }
  
  static void clearAppBadge() {
    if (kIsWeb) {
      clearAppBadgeHelper();
    }
  }
}
