import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'auth_service.dart';
import '../core/constants/user_roles.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    print('🔔 Initializing NotificationService...');

    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _getFCMToken();

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Set up message handlers
        _setupMessageHandlers();

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        print('✅ NotificationService initialized successfully!');
      } else {
        print('⚠️ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('🔑 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveFCMTokenToFirestore(_fcmToken!);

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveFCMTokenToFirestore(newToken);
          print('🔄 FCM Token refreshed: $newToken');
        });
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final userRole = AuthService().getUserRole(userId);
        if (userRole == UserRole.citizen) {
          await _firestore.collection('citizens').doc(userId).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': GetPlatform.isAndroid ? 'android' : 'ios',
              'lastActive': FieldValue.serverTimestamp(),
            }
          }, SetOptions(merge: true));
        } else if (userRole == UserRole.contractor) {
          await _firestore.collection('contractors').doc(userId).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': GetPlatform.isAndroid ? 'android' : 'ios',
              'lastActive': FieldValue.serverTimestamp(),
            }
          }, SetOptions(merge: true));
        } else if (userRole == UserRole.admin) {
          await _firestore.collection('admins').doc(userId).set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': GetPlatform.isAndroid ? 'android' : 'ios',
              'lastActive': FieldValue.serverTimestamp(),
            }
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'srscs_high_importance', // id
      'SRSCS Notifications', // title
      description: 'Important notifications for complaint updates and alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('✅ Local notifications initialized');
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      _showLocalNotification(message);
    });

    // Background/Terminated - User taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped (background)');
      _handleNotificationNavigation(message.data);
    });

    // Check if app was opened from terminated state
    _checkInitialMessage();
  }

  /// Check if app was opened by tapping a notification (terminated state)
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 App opened from notification (terminated state)');
      await Future.delayed(const Duration(seconds: 1));
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    if (notification != null) {
      // Determine notification importance based on type
      Importance importance = Importance.high;
      Priority priority = Priority.high;
      String channelId = 'srscs_high_importance';

      if (data['type'] == 'urgent_notice' || data['type'] == 'emergency') {
        importance = Importance.max;
        priority = Priority.max;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'SRSCS Notifications',
        channelDescription:
            'Important notifications for complaint updates and alerts',
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: _encodePayload(data),
      );
    }
  }

  /// Handle notification tap (local notification)
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped');
    if (response.payload != null) {
      Map<String, dynamic> data = _decodePayload(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  /// Navigate based on notification type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    String? type = data['type'];
    String? id = data['id'];

    print('🧭 Navigating to: $type (ID: $id)');

    // Delay navigation to ensure app is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      switch (type) {
        case 'complaint_status':
        case 'complaint_update':
          Get.toNamed('/tracking');
          break;

        case 'urgent_notice':
        case 'notice':
        case 'emergency':
          Get.toNamed('/dashboard');
          break;

        case 'chat_message':
        case 'admin_reply':
          Get.toNamed('/chat');
          break;

        case 'news':
          Get.toNamed('/dashboard');
          break;

        default:
          Get.toNamed('/dashboard');
      }
    });
  }

  /// Encode data to string payload
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode string payload to data map
  Map<String, dynamic> _decodePayload(String payload) {
    Map<String, dynamic> data = {};
    for (String pair in payload.split('&')) {
      List<String> parts = pair.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }
    return data;
  }

  /// Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? complaintUpdates,
    bool? urgentNotices,
    bool? chatMessages,
    bool? newsAlerts,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        Map<String, bool> preferences = {};

        if (complaintUpdates != null) {
          preferences['complaintUpdates'] = complaintUpdates;
        }
        if (urgentNotices != null) {
          preferences['urgentNotices'] = urgentNotices;
        }
        if (chatMessages != null) {
          preferences['chatMessages'] = chatMessages;
        }
        if (newsAlerts != null) {
          preferences['newsAlerts'] = newsAlerts;
        }

        await _firestore.collection('citizens').doc(userId).set({
          'notificationPreferences': preferences,
        }, SetOptions(merge: true));

        print('✅ Notification preferences updated');
      }
    } catch (e) {
      print('❌ Error updating notification preferences: $e');
    }
  }

  /// Get current notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('citizens').doc(userId).get();
        final prefs =
            doc.data()?['notificationPreferences'] as Map<String, dynamic>?;

        return {
          'complaintUpdates': prefs?['complaintUpdates'] ?? true,
          'urgentNotices': prefs?['urgentNotices'] ?? true,
          'chatMessages': prefs?['chatMessages'] ?? true,
          'newsAlerts': prefs?['newsAlerts'] ?? false,
        };
      }
    } catch (e) {
      print('❌ Error getting notification preferences: $e');
    }

    // Default preferences
    return {
      'complaintUpdates': true,
      'urgentNotices': true,
      'chatMessages': true,
      'newsAlerts': false,
    };
  }
}
