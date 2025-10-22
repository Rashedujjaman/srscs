# 🔔 Notification System - Current Status & Future Implementation

## 📋 Overview

This document outlines the **notification scenarios** in the SRSCS (Smart Road Safety Complaint System) and details what is currently implemented vs. what needs to be implemented.

---

## 🎯 Notification Scenarios

### **CURRENTLY IMPLEMENTED ✅**

#### 1. **In-App Notice Notifications** (Dashboard)

**Status**: ✅ FULLY IMPLEMENTED

**What it does**:

- Shows active notices on the dashboard
- Displays unread notice count badge
- Marks notices as read when opened
- Prioritizes urgent notices

**User sees notification when**:

- Admin creates a new notice in Firestore (`/notices` collection)
- Notice types:
  - 🚨 **Emergency**: Road accidents, immediate hazards
  - ⚠️ **Warning**: Weather alerts, traffic disruptions
  - 🔧 **Maintenance**: Scheduled road work
  - ℹ️ **Info**: General announcements

**Where user sees it**:

1. **Dashboard Screen** - Notification bell icon with red badge count
2. **Urgent Notices Section** - Shows critical/high priority notices
3. **All Notices Section** - Shows all active notices

**Code Implementation**:

```dart
// Location: lib/features/dashboard/presentation/screens/dashboard_screen.dart

// Notification Badge (Line 274-306)
Consumer<DashboardProvider>(
  builder: (context, dashboardProvider, child) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            _showAllNotices(context, dashboardProvider.noticesList);
          },
        ),
        if (dashboardProvider.unreadNoticeCount > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${dashboardProvider.unreadNoticeCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),
```

**How it works**:

1. Admin adds notice to Firestore → `/notices/{noticeId}`
2. Dashboard loads notices → `getActiveNotices()`
3. Counts unread notices → `getUnreadNoticeCount(userId)`
4. Shows badge on bell icon
5. When user opens notice → marks as read in `/citizens/{userId}/readNotices/{noticeId}`
6. Badge count decreases automatically

**Files involved**:

- `dashboard_screen.dart` - UI display
- `dashboard_provider.dart` - State management
- `dashboard_remote_data_source.dart` - Firestore operations
- `mark_notice_as_read.dart` - Use case for marking as read

---

### **NOT IMPLEMENTED ❌ (Planned Features)**

#### 2. **Push Notifications** (Firebase Cloud Messaging)

**Status**: ❌ NOT IMPLEMENTED

**When user should be notified**:

##### A. **Complaint Status Updates**

User receives push notification when:

- ✅ Complaint moves to "Under Review" (admin starts processing)
- ✅ Complaint moves to "In Progress" (work has started)
- ✅ Complaint is "Resolved" (issue fixed)
- ❌ Complaint is "Rejected" (with reason)
- 📝 Admin adds a comment/response

**Example Notifications**:

```
"Your complaint #12345 is now Under Review"
"Good news! Your pothole complaint has been Resolved"
"Your complaint was rejected. Tap to view reason."
```

##### B. **Urgent Notices**

User receives push notification when:

- 🚨 Emergency notice is created (Critical urgency)
- ⚠️ Warning notice affects user's area (location-based)
- 🔔 New notice with user-relevant keywords

**Example Notifications**:

```
"EMERGENCY: Road accident on Dhaka-Chittagong Highway"
"WARNING: Heavy rainfall expected in your area"
"NOTICE: Road maintenance in Mirpur starting tomorrow"
```

##### C. **Chat Responses**

User receives push notification when:

- 💬 Admin replies to user's chat message
- 📧 New message in support conversation

**Example Notifications**:

```
"Admin replied to your message"
"You have a new message from SRSCS Support"
```

##### D. **News Updates**

User receives push notification when:

- 📰 Important news (Priority 5) is published
- 🎯 News relevant to user's previous complaints

**Example Notifications**:

```
"NEW: AI-Powered Road Monitoring System Launched"
"UPDATE: Road Repair Plan 2025 Announced"
```

---

## 🔧 What Needs to Be Implemented

### **1. Add Firebase Cloud Messaging (FCM) Package**

**Update `pubspec.yaml`**:

```yaml
dependencies:
  firebase_messaging: ^14.7.6 # Add this
  flutter_local_notifications: ^16.3.0 # For foreground notifications
```

### **2. Create Notification Service**

**File**: `lib/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

    // Handle background/terminated notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('citizens')
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground notifications
  void _handleForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        notification.title ?? 'SRSCS',
        notification.body ?? '',
        message.data,
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'srscs_channel',
      'SRSCS Notifications',
      channelDescription: 'Notifications for complaint updates and notices',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    _navigateBasedOnNotification(data);
  }

  // Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    // Parse payload and navigate
    print('Local notification tapped: ${response.payload}');
  }

  // Navigate based on notification type
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    String? type = data['type'];
    String? id = data['id'];

    switch (type) {
      case 'complaint_status':
        Get.toNamed('/tracking'); // Navigate to complaint tracking
        break;
      case 'urgent_notice':
        Get.toNamed('/dashboard'); // Navigate to dashboard
        break;
      case 'chat_message':
        Get.toNamed('/chat'); // Navigate to chat
        break;
      case 'news':
        Get.toNamed('/dashboard'); // Navigate to dashboard
        break;
      default:
        Get.toNamed('/dashboard');
    }
  }
}
```

### **3. Backend Functions (Firebase Cloud Functions)**

**File**: `functions/index.js` (create in Firebase project)

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Send notification when complaint status changes
exports.onComplaintStatusChange = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed
    if (beforeData.status !== afterData.status) {
      const userId = afterData.userId;
      const complaintId = context.params.complaintId;
      const newStatus = afterData.status;

      // Get user's FCM token
      const userDoc = await admin
        .firestore()
        .collection("citizens")
        .doc(userId)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;

      if (fcmToken) {
        const message = {
          notification: {
            title: "Complaint Status Update",
            body: `Your complaint #${complaintId.substring(
              0,
              6
            )} is now ${newStatus}`,
          },
          data: {
            type: "complaint_status",
            complaintId: complaintId,
            status: newStatus,
          },
          token: fcmToken,
        };

        await admin.messaging().send(message);
        console.log("Notification sent to user:", userId);
      }
    }
  });

// Send notification for urgent notices
exports.onUrgentNoticeCreated = functions.firestore
  .document("notices/{noticeId}")
  .onCreate(async (snapshot, context) => {
    const noticeData = snapshot.data();

    // Only send for emergency/warning types
    if (noticeData.type === "emergency" || noticeData.type === "warning") {
      // Get all users with FCM tokens
      const usersSnapshot = await admin
        .firestore()
        .collection("citizens")
        .where("fcmToken", "!=", null)
        .get();

      const tokens = usersSnapshot.docs.map((doc) => doc.data().fcmToken);

      if (tokens.length > 0) {
        const message = {
          notification: {
            title:
              noticeData.type === "emergency" ? "🚨 EMERGENCY" : "⚠️ WARNING",
            body: noticeData.title,
          },
          data: {
            type: "urgent_notice",
            noticeId: context.params.noticeId,
          },
          tokens: tokens,
        };

        await admin.messaging().sendMulticast(message);
        console.log("Urgent notice sent to", tokens.length, "users");
      }
    }
  });

// Send notification for chat replies
exports.onAdminChatReply = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();

    // Only send if message is from admin
    if (messageData.isAdmin) {
      const userId = context.params.userId;

      // Get user's FCM token
      const userDoc = await admin
        .firestore()
        .collection("citizens")
        .doc(userId)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;

      if (fcmToken) {
        const message = {
          notification: {
            title: "Admin Reply",
            body: messageData.message,
          },
          data: {
            type: "chat_message",
            userId: userId,
          },
          token: fcmToken,
        };

        await admin.messaging().send(message);
      }
    }
  });
```

### **4. Update main.dart**

```dart
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}
```

### **5. Update Firestore Schema**

**Add to `citizens` collection**:

```javascript
/citizens/{userId}
  - fcmToken: string (Device FCM token)
  - fcmTokenUpdatedAt: Timestamp
  - notificationPreferences: {
      complaintUpdates: boolean (default: true)
      urgentNotices: boolean (default: true)
      chatMessages: boolean (default: true)
      newsAlerts: boolean (default: false)
    }
```

---

## 📊 Current Implementation Summary

| Feature                      | Status             | Location                            |
| ---------------------------- | ------------------ | ----------------------------------- |
| **In-App Notice Badge**      | ✅ Implemented     | `dashboard_screen.dart`             |
| **Mark Notice as Read**      | ✅ Implemented     | `mark_notice_as_read.dart`          |
| **Unread Count Tracking**    | ✅ Implemented     | `dashboard_remote_data_source.dart` |
| **Urgent Notice Display**    | ✅ Implemented     | `dashboard_screen.dart`             |
| **Push Notifications**       | ❌ Not Implemented | -                                   |
| **FCM Token Management**     | ❌ Not Implemented | -                                   |
| **Cloud Functions**          | ❌ Not Implemented | -                                   |
| **Notification Preferences** | ❌ Not Implemented | -                                   |

---

## 🎯 User Notification Flow (When Fully Implemented)

### Scenario 1: Complaint Status Update

```
1. Admin updates complaint status → Firestore
2. Cloud Function triggers → onComplaintStatusChange
3. Function fetches user's FCM token → from /citizens/{userId}
4. Sends push notification → Firebase Messaging
5. User receives notification → Device
6. User taps notification → Opens tracking screen
```

### Scenario 2: Urgent Notice

```
1. Admin creates emergency notice → Firestore /notices
2. Cloud Function triggers → onUrgentNoticeCreated
3. Function fetches all FCM tokens → from /citizens
4. Sends multicast notification → Firebase Messaging
5. All users receive notification → Devices
6. User taps notification → Opens dashboard with notice
```

### Scenario 3: Chat Reply

```
1. Admin sends chat message → Firebase Realtime DB
2. Cloud Function triggers → onAdminChatReply
3. Function fetches user's FCM token
4. Sends push notification
5. User receives notification
6. User taps notification → Opens chat screen
```

---

## 📝 Implementation Checklist

- [ ] Add FCM packages to `pubspec.yaml`
- [ ] Create `notification_service.dart`
- [ ] Update `main.dart` to initialize notifications
- [ ] Add FCM token field to Firestore schema
- [ ] Create Firebase Cloud Functions project
- [ ] Deploy Cloud Functions for:
  - [ ] Complaint status changes
  - [ ] Urgent notices
  - [ ] Chat replies
  - [ ] News alerts (optional)
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Configure APNs for iOS
- [ ] Add notification preferences screen
- [ ] Update Firestore security rules

---

## 🔒 Security Considerations

1. **Token Security**: FCM tokens stored in Firestore with proper security rules
2. **User Privacy**: Only send notifications user has opted into
3. **Rate Limiting**: Prevent notification spam
4. **Data Minimization**: Only include necessary data in notification payload

---

## 📱 Testing Push Notifications

### Using Firebase Console:

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification details
4. Select target (device, topic, or user segment)
5. Send test notification

### Using FCM REST API:

```bash
curl -X POST "https://fcm.googleapis.com/fcm/send" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test from SRSCS"
    },
    "data": {
      "type": "test",
      "id": "123"
    }
  }'
```

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)

---

**Status**: In-app notifications ✅ | Push notifications ❌ (Planned)

**Priority**: HIGH - Push notifications significantly improve user engagement and complaint resolution time.
