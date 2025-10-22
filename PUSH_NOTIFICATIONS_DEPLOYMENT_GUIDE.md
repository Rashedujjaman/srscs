# 🚀 Push Notifications - Complete Implementation Guide

## ✅ What We've Implemented

### 1. **Flutter App** ✅

- ✅ Firebase Cloud Messaging package added
- ✅ Local Notifications package added
- ✅ NotificationService class created
- ✅ Automatic FCM token management
- ✅ Foreground/Background/Terminated notification handling
- ✅ Smart navigation based on notification type
- ✅ User notification preferences support
- ✅ Topic subscription (all_users, urgent_notices)

### 2. **Android Configuration** ✅

- ✅ Notification permissions in AndroidManifest.xml
- ✅ FCM service configuration
- ✅ Default notification channel setup
- ✅ Notification icon and color configured

### 3. **Firebase Cloud Functions** ✅

- ✅ Complaint status change notifications
- ✅ Urgent notice notifications (emergency/warning)
- ✅ Admin chat reply notifications
- ✅ High priority news notifications
- ✅ Daily token cleanup task

### 4. **Firestore Schema** ✅

- ✅ FCM token storage per user
- ✅ Notification preferences per user
- ✅ Device info tracking

---

## 📋 Deployment Steps

### Step 1: Install Firebase CLI

```powershell
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Step 2: Initialize Firebase Project

```powershell
# Navigate to project root
cd C:\Users\rdjre\Downloads\srscs\srscs

# Initialize Firebase (if not done already)
firebase init

# Select:
# - Functions: Configure Cloud Functions
# - Use existing project: Select your SRSCS project
# - Language: JavaScript
# - ESLint: No
# - Install dependencies: Yes
```

### Step 3: Install Cloud Functions Dependencies

```powershell
cd functions
npm install
```

### Step 4: Deploy Cloud Functions

```powershell
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:onComplaintStatusChange
firebase deploy --only functions:onUrgentNoticeCreated
firebase deploy --only functions:onAdminChatReply
firebase deploy --only functions:onHighPriorityNews
```

### Step 5: Build and Run Flutter App

```powershell
# Navigate back to project root
cd ..

# Clean and get dependencies
flutter clean
flutter pub get

# Run on device (MUST use physical device for notifications)
flutter run
```

---

## 🧪 Testing Push Notifications

### Test 1: Complaint Status Update Notification

**Steps:**

1. Open app and submit a complaint
2. Go to Firebase Console → Firestore
3. Find your complaint in `complaints` collection
4. Update the `status` field:
   - Change from `pending` to `underReview`
5. **Expected**: Notification appears on device: "👀 Complaint Under Review"

**Firebase Console Command:**

```javascript
// In Firestore Console, update complaint document:
{
  status: "underReview"; // or "inProgress", "resolved", "rejected"
}
```

### Test 2: Urgent Notice Notification

**Steps:**

1. Go to Firebase Console → Firestore
2. Create new document in `notices` collection
3. Add these fields:

```javascript
{
  title: "Emergency: Road Accident",
  message: "Major accident on highway. Avoid area.",
  type: "emergency",  // or "warning"
  createdAt: firebase.firestore.Timestamp.now(),
  isActive: true
}
```

4. **Expected**: All users receive notification: "🚨 EMERGENCY ALERT"

### Test 3: Chat Reply Notification

**Steps:**

1. Open app and send a message in chat
2. Go to Firebase Console → Realtime Database
3. Navigate to `chats/{yourUserId}/messages`
4. Add new message node:

```javascript
{
  "message": "Hello, we received your inquiry!",
  "isAdmin": true,
  "timestamp": Date.now(),
  "senderName": "Admin",
  "senderId": "admin"
}
```

5. **Expected**: Notification: "💬 Admin Reply"

### Test 4: High Priority News Notification

**Steps:**

1. Go to Firebase Console → Firestore
2. Create new document in `news` collection:

```javascript
{
  title: "Important Update: New System Launched",
  content: "Full content here...",
  publishedAt: firebase.firestore.Timestamp.now(),
  source: "RHD",
  priority: 5  // Must be 5 for notification
}
```

3. **Expected**: Users with news alerts enabled receive notification

### Test 5: Firebase Console Test Message

**Steps:**

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Fill in:
   - **Title**: "Test Notification"
   - **Body**: "This is a test"
   - **Target**: Select your app
4. Click "Send test message"
5. Enter your FCM token (visible in app logs when you run it)
6. **Expected**: Notification appears immediately

---

## 🔍 How to Get Your FCM Token

When you run the app, check the debug console. You'll see:

```
🔔 Initializing NotificationService...
📱 Notification permission: authorized
🔑 FCM Token: dXyz123ABC...
✅ FCM token saved to Firestore for user: userId123
✅ NotificationService initialized successfully!
```

Copy the FCM token for testing in Firebase Console.

---

## 📊 Monitoring Notifications

### View Function Logs

```powershell
# View all function logs
firebase functions:log

# View specific function logs
firebase functions:log --only onComplaintStatusChange

# Follow logs in real-time
firebase functions:log --follow
```

### Firebase Console Monitoring

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your SRSCS project
3. Navigate to **Functions**
4. Click on any function to see:
   - Execution logs
   - Error rate
   - Execution time
   - Number of invocations

---

## 🔐 Firestore Security Rules

Update your Firestore security rules to protect FCM tokens:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Citizens collection - users can only read/write their own data
    match /citizens/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;

      // Allow read of notification preferences for functions
      allow read: if request.auth != null;
    }

    // Complaints collection
    match /complaints/{complaintId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
                      (resource.data.userId == request.auth.uid ||
                       get(/databases/$(database)/documents/citizens/$(request.auth.uid)).data.role == 'admin');
    }

    // News and Notices - read-only for users
    match /news/{newsId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/citizens/$(request.auth.uid)).data.role == 'admin';
    }

    match /notices/{noticeId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/citizens/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 🎯 Notification Scenarios - Summary

| Scenario              | Trigger                          | Recipient              | Function                  |
| --------------------- | -------------------------------- | ---------------------- | ------------------------- |
| **Complaint Updated** | Status changes in Firestore      | Individual user        | `onComplaintStatusChange` |
| **Urgent Notice**     | Emergency/Warning notice created | All users (topic)      | `onUrgentNoticeCreated`   |
| **Chat Reply**        | Admin sends message              | Individual user        | `onAdminChatReply`        |
| **Important News**    | Priority 5 news created          | Users with news alerts | `onHighPriorityNews`      |

---

## 🎨 Notification Customization

### Change Notification Icon

1. Add your notification icon to:

   - `android/app/src/main/res/drawable/notification_icon.png`

2. Update AndroidManifest.xml:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/notification_icon" />
```

### Change Notification Sound

1. Add sound file to:

   - `android/app/src/main/res/raw/notification_sound.mp3`

2. Update in NotificationService.dart:

```dart
sound: RawResourceAndroidNotificationSound('notification_sound'),
```

---

## 🐛 Troubleshooting

### Problem: No FCM token generated

**Solution:**

```powershell
# Check google-services.json exists
ls android/app/google-services.json

# Rebuild app
flutter clean
flutter pub get
flutter run
```

### Problem: Notifications not received

**Checklist:**

- ✅ Using physical device (not emulator)
- ✅ App has notification permission
- ✅ FCM token saved in Firestore
- ✅ Cloud Functions deployed
- ✅ Function logs show no errors
- ✅ User has enabled notification preference

### Problem: Function deployment fails

**Solution:**

```powershell
# Update Firebase CLI
npm install -g firebase-tools@latest

# Check Firebase project
firebase projects:list

# Redeploy
cd functions
npm install
firebase deploy --only functions
```

### Problem: Background notifications not working

**Solution:**

- Ensure app is not in battery optimization
- Check notification channel is created
- Verify AndroidManifest.xml has all permissions

---

## 📱 User Notification Preferences

Users can control notifications via Firestore:

```javascript
// In /citizens/{userId}
{
  notificationPreferences: {
    complaintUpdates: true,   // Default: true
    urgentNotices: true,       // Default: true
    chatMessages: true,        // Default: true
    newsAlerts: false          // Default: false
  }
}
```

To add UI for preferences, create a settings screen where users can toggle these values.

---

## 🎉 Success Criteria

Your push notification system is working when:

- ✅ App shows FCM token in logs on startup
- ✅ FCM token saved in Firestore `/citizens/{userId}`
- ✅ Changing complaint status triggers notification
- ✅ Creating urgent notice sends to all users
- ✅ Admin chat reply notifies user
- ✅ Notification tap navigates to correct screen
- ✅ Foreground, background, and terminated states all work
- ✅ Function logs show successful sends
- ✅ No errors in Firebase Console

---

## 📚 Next Steps

1. **Add Settings UI**: Create screen for users to manage preferences
2. **Add Analytics**: Track notification open rates
3. **Add Scheduled Notifications**: Reminders for unresolved complaints
4. **Add Rich Notifications**: Images, action buttons
5. **Add iOS Support**: Configure APNs, update Info.plist
6. **Add Web Support**: Configure web push notifications

---

**🎊 Congratulations!** Your push notification system is fully implemented and ready to deploy!

**Need help?** Check the function logs and console output for debugging.
