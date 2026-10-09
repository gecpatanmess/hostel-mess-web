import 'main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';
import 'badge_helper.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> saveToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token == null) return;
      print("FCM Token: $token");

      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');
      final identifier = prefs.getString('identifier');

      if (userType == 'student' && identifier != null) {
        final snap = await FirebaseDatabase.instance.ref('hostelData_$globalHostelMode/students')
            .orderByChild('name')
            .equalTo(identifier)
            .get();
            
        if (snap.exists && snap.value != null) {
          Map students = snap.value as Map;
          for (var key in students.keys) {
            await FirebaseDatabase.instance.ref('hostelData_$globalHostelMode/students/$key/fcmToken').set(token);
            print("Saved FCM token for student $identifier");
            break;
          }
        }
      } else if (userType == 'admin' && identifier != null) {
        String safePhone = identifier.replaceAll(RegExp(r'[.#$\[\]]'), '');
        // Save Admin token in BOTH folders so they get notifications from both Boys and Girls
        await FirebaseDatabase.instance.ref('hostelData_boys/admin/fcmTokens/$safePhone').set(token);
        await FirebaseDatabase.instance.ref('hostelData_girls/admin/fcmTokens/$safePhone').set(token);
        print("Saved FCM token for admin $identifier in both sections");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

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
        // Save FCM Token
        await saveToken();
        
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

  static Future<void> sendPushNotificationToStudents(String title, String body) async {
    try {
      // 1. Get all student tokens
      List<String> tokens = [];
      final snap = await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/students').get();
      if (snap.exists && snap.value != null) {
        if (snap.value is List) {
          for (var s in (snap.value as List)) {
            if (s != null && s is Map && s['fcmToken'] != null) {
              tokens.add(s['fcmToken'].toString());
            }
          }
        } else if (snap.value is Map) {
          Map students = snap.value as Map;
          for (var key in students.keys) {
            if (students[key] != null && students[key] is Map && students[key]['fcmToken'] != null) {
              tokens.add(students[key]['fcmToken'].toString());
            }
          }
        }
      }

      if (tokens.isEmpty) {
        print("No student tokens found.");
        return;
      }

      // Batch tokens in chunks of 400 (FCM limit is 500)
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      const batchSize = 400;
      for (int i = 0; i < tokens.length; i += batchSize) {
        final batch = tokens.sublist(i, i + batchSize > tokens.length ? tokens.length : i + batchSize);
        try {
          await dio.post(
            'https://hostel-backend-pdph.onrender.com/send-notification',
            data: {
              'title': title,
              'body': body,
              'tokens': batch,
            },
          );
        } catch (e) {
          print("Error sending notification batch: $e");
        }
      }
      print("Notification sent successfully to ${tokens.length} students");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  static Future<void> sendPushNotificationToAdmins(String title, String body) async {
    try {
      // 1. Get all admin tokens
      List<String> tokens = [];
      final snap = await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/admin/fcmTokens').get();
      if (snap.exists && snap.value != null && snap.value is Map) {
        Map admins = snap.value as Map;
        for (var key in admins.keys) {
          if (admins[key] != null) {
            tokens.add(admins[key].toString());
          }
        }
      }

      if (tokens.isEmpty) {
        print("No admin tokens found.");
        return;
      }

      // 2. Call our Node.js backend to send the notification
      final dio = Dio();
      final response = await dio.post(
        'https://hostel-backend-pdph.onrender.com/send-notification',
        data: {
          'title': title,
          'body': body,
          'tokens': tokens,
        },
      );
      print("Admin Notification sent successfully: ${response.data}");
    } catch (e) {
      print("Error sending admin notification: $e");
    }
  }

  static Future<void> sendPushNotificationToSpecificStudents(List<String> studentNames, String title, String body) async {
    try {
      List<String> tokens = [];
      final snap = await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/students').get();
      if (snap.exists && snap.value != null) {
        if (snap.value is List) {
          for (var s in (snap.value as List)) {
            if (s != null && s is Map && s['fcmToken'] != null && studentNames.contains(s['name'])) {
              tokens.add(s['fcmToken'].toString());
            }
          }
        } else if (snap.value is Map) {
          Map students = snap.value as Map;
          for (var key in students.keys) {
            if (students[key] != null && students[key] is Map && students[key]['fcmToken'] != null && studentNames.contains(students[key]['name'])) {
              tokens.add(students[key]['fcmToken'].toString());
            }
          }
        }
      }

      if (tokens.isEmpty) {
        print("No tokens found for the specified students.");
        return;
      }

      final dio = Dio();
      final response = await dio.post(
        'https://hostel-backend-pdph.onrender.com/send-notification',
        data: {
          'title': title,
          'body': body,
          'tokens': tokens,
        },
      );
      print("Specific Student Notification sent successfully: ${response.data}");
    } catch (e) {
      print("Error sending specific student notification: $e");
    }
  }
}
