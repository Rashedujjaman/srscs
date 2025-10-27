# 🚀 SRSCS Notification System - Deployment Guide

## 📋 Overview

This guide will help you deploy the complete notification system with:

- ✅ New complaint notifications to admins
- ✅ Task assignment notifications to contractors
- ✅ Chat message notifications (bidirectional)
- ✅ Role-based topic subscriptions
- ✅ Multi-device support

---

## 🔧 Step 1: Deploy New Cloud Functions

### 1.1 Navigate to Functions Directory

```powershell
cd functions
```

### 1.2 Deploy All Functions

```powershell
firebase deploy --only functions
```

**Expected Output:**

```
✔ functions[onComplaintStatusChange(us-central1)] Successful update operation.
✔ functions[onComplaintCreated(us-central1)] Successful create operation.
✔ functions[onComplaintAssigned(us-central1)] Successful create operation.
✔ functions[onUrgentNoticeCreated(us-central1)] Successful update operation.
✔ functions[onHighPriorityNews(us-central1)] Successful update operation.
✔ functions[cleanupInvalidTokens(us-central1)] Successful update operation.

✔ Deploy complete!
```

### 1.3 Verify Deployment

```powershell
firebase functions:list
```

**You should see:**

- ✅ `onComplaintStatusChange` - Notify complaint creator on status change
- ✅ `onComplaintCreated` - **NEW** - Notify admins on new complaint
- ✅ `onComplaintAssigned` - **NEW** - Notify contractor on task assignment
- ✅ `onUrgentNoticeCreated` - Broadcast urgent notices
- ✅ `onHighPriorityNews` - Notify on high priority news
- ✅ `cleanupInvalidTokens` - Daily token cleanup (2 AM)

---

## 💬 Step 2: Enable Chat Notifications (Optional)

### 2.1 Check Realtime Database Status

**Go to Firebase Console:**

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Realtime Database" in left menu

**If you see "Create Database" button:**

- Your Realtime Database is NOT enabled yet
- Continue to Step 2.2

**If you see your database URL:**

- Your Realtime Database is already enabled ✅
- Skip to Step 2.3

### 2.2 Enable Realtime Database

1. Click **"Create Database"**
2. Select Database location: **asia-southeast1** (Singapore - closest to Bangladesh)
3. Choose Security Rules:
   - **Development:** Start in **test mode** (allows all reads/writes)
   - **Production:** Start in **locked mode** (we'll set rules manually)
4. Click **"Enable"**

### 2.3 Set Realtime Database Rules

**Development Rules (Test Only):**

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**Production Rules (Recommended):**

```json
{
  "rules": {
    "chats": {
      "$userId": {
        ".read": "auth != null && (auth.uid == $userId || root.child('admins').child(auth.uid).exists())",
        ".write": "auth != null && (auth.uid == $userId || root.child('admins').child(auth.uid).exists())",
        "messages": {
          "$messageId": {
            ".validate": "newData.hasChildren(['message', 'timestamp', 'isAdmin'])"
          }
        }
      }
    }
  }
}
```

**Explanation:**

- Citizens can only read/write their own chat
- Admins can read/write ALL chats
- Messages must have: message, timestamp, isAdmin fields

### 2.4 Uncomment Chat Functions

**Open:** `functions/index.js`

**Find these two commented sections:**

```javascript
/*
exports.onAdminChatReply = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    ...
  });
*/

/*
exports.onCitizenChatMessage = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    ...
  });
*/
```

**Remove the comment markers:**

```javascript
exports.onAdminChatReply = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    ...
  });

exports.onCitizenChatMessage = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    ...
  });
```

### 2.5 Redeploy Functions

```powershell
cd functions
firebase deploy --only functions
```

**Expected Output:**

```
✔ functions[onAdminChatReply(us-central1)] Successful create operation.
✔ functions[onCitizenChatMessage(us-central1)] Successful create operation.
```

---

## 📱 Step 3: Update Flutter App

### 3.1 No Code Changes Needed!

The following files have already been updated:

- ✅ `login_screen.dart` - Role-based topic subscriptions
- ✅ `route_manager.dart` - Topic unsubscription on logout
- ✅ `notification_service.dart` - Multi-device token management

### 3.2 Test the App

**Option A: Hot Restart (Recommended)**

```
Press Ctrl+Shift+F5 in VS Code
OR
Run > Restart Without Debugging
```

**Option B: Full Rebuild**

```powershell
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Step 4: Test Notifications

### Test 1: New Complaint Notification (Admin)

**Steps:**

1. Login as **Citizen** on Device 1
2. Submit a new complaint
3. Login as **Admin** on Device 2
4. **Expected:** Admin receives notification: "📋 New Complaint Received"

**Troubleshooting:**

- Check Firebase Console > Functions > Logs
- Look for: `New complaint created: [complaintId]`
- If no notification, check admin's `fcmTokens` array in Firestore

---

### Test 2: Task Assignment Notification (Contractor)

**Steps:**

1. Login as **Admin** on Device 1
2. Assign complaint to a contractor
3. Login as **Contractor** on Device 2
4. **Expected:** Contractor receives: "🔧 New Task Assigned"

**Troubleshooting:**

- Check Function logs: `Complaint [id] assigned to contractor: [contractorId]`
- Verify contractor's `fcmTokens` in Firestore

---

### Test 3: Complaint Status Update (Citizen)

**Steps:**

1. Login as **Citizen** on Device 1 and submit complaint
2. Login as **Admin** on Device 2
3. Change complaint status to "In Progress"
4. **Expected:** Citizen receives: "🔧 Work in Progress"

**Status:** ✅ Already working (existing function)

---

### Test 4: Chat Notification - Admin to Citizen

**Prerequisites:** Realtime Database must be enabled

**Steps:**

1. Login as **Citizen** on Device 1
2. Open chat, send message to admin
3. Login as **Admin** on Device 2
4. Reply to citizen's message
5. **Expected:** Citizen receives: "💬 New Message from Admin"

**Troubleshooting:**

- Verify Realtime Database is enabled
- Check database path: `chats/{userId}/messages/{messageId}`
- Verify `isAdmin: true` field in message

---

### Test 5: Chat Notification - Citizen to Admin

**Steps:**

1. Login as **Citizen** on Device 1
2. Send chat message to admin
3. Login as **Admin** on Device 2
4. **Expected:** Admin receives: "💬 New Message from [Citizen Name]"

**Troubleshooting:**

- Check Function logs: `New chat message from user [userId]`
- Verify all admins have `fcmTokens` in Firestore

---

### Test 6: Role-Based Topics

**Test 6.1: Citizen Topics**

```
Login as Citizen
Expected Topics:
- all_users
- urgent_notices
- citizen_updates
```

**Test 6.2: Contractor Topics**

```
Login as Contractor
Expected Topics:
- all_users
- urgent_notices
- contractor_updates
```

**Test 6.3: Admin Topics**

```
Login as Admin
Expected Topics:
- all_users
- urgent_notices
- admin_updates
```

**Verify Subscriptions:**

- Check logs in VS Code debug console
- Look for: `✅ Subscribed to [topic] topic`

---

## 🐛 Troubleshooting

### Issue 1: Notifications Not Received

**Check 1: FCM Token Exists**

```
Firebase Console > Firestore > citizens/contractors/admins
Select user document
Verify: fcmTokens array has at least 1 token
```

**Check 2: Notification Permissions**

```dart
// Check in app
final prefs = await NotificationService().getNotificationPreferences();
print(prefs); // Should show enabled preferences
```

**Check 3: Cloud Function Logs**

```
Firebase Console > Functions > Logs
Look for errors or "No FCM tokens found"
```

---

### Issue 2: Function Not Triggering

**Check 1: Function Deployed**

```powershell
firebase functions:list
```

**Check 2: Firestore Trigger Path Correct**

```javascript
// For complaints
.document("complaints/{complaintId}")

// For chat (Realtime DB)
.ref("chats/{userId}/messages/{messageId}")
```

**Check 3: Function Logs**

```
Firebase Console > Functions > [function name] > Logs
Look for execution logs
```

---

### Issue 3: Chat Notifications Not Working

**Check 1: Realtime Database Enabled**

```
Firebase Console > Realtime Database
Should see database URL, not "Create Database" button
```

**Check 2: Database Rules Set**

```
Firebase Console > Realtime Database > Rules tab
Verify read/write rules are set
```

**Check 3: Chat Functions Uncommented**

```javascript
// In functions/index.js
// These should NOT be commented:
exports.onAdminChatReply = functions.database...
exports.onCitizenChatMessage = functions.database...
```

**Check 4: Data Structure Correct**

```json
{
  "chats": {
    "userId123": {
      "messages": {
        "messageId1": {
          "message": "Hello admin",
          "timestamp": 1698400000000,
          "isAdmin": false
        }
      }
    }
  }
}
```

---

### Issue 4: Topic Notifications Not Broadcasting

**Check 1: Topic Subscriptions**

```dart
// In app logs, after login:
✅ Subscribed to all_users topic
✅ Subscribed to urgent_notices topic
✅ Subscribed to [role]_updates topic
```

**Check 2: Send Test Topic Notification**

```
Firebase Console > Cloud Messaging > Send test message
Select: Topic
Topic name: all_users
Send notification
```

**Check 3: Topic Name Spelling**

```
Correct: all_users, urgent_notices, citizen_updates
Wrong: allUsers, urgentNotices, citizen-updates
```

---

## 📊 Monitoring & Analytics

### View Function Logs

```
Firebase Console > Functions > [function name] > Logs
```

**Look for:**

- ✅ Success: `Notification sent to X device(s)`
- ⚠️ Warning: `No FCM tokens found for user`
- ❌ Error: `Error sending notification: [error]`

### View Firestore Data

```
Firebase Console > Firestore Database
```

**Check:**

- `fcmTokens` array populated for users
- `notificationPreferences` set correctly
- `lastFcmTokenUpdate` timestamp recent

### Test Notification Delivery

```
Firebase Console > Cloud Messaging > Send test message
```

**Test Scenarios:**

1. Send to specific device token
2. Send to topic (all_users)
3. Check delivery report

---

## 🎯 Notification Summary

| Notification Type       | Trigger                  | Recipients                    | Status                  |
| ----------------------- | ------------------------ | ----------------------------- | ----------------------- |
| Complaint status change | Complaint status updated | Complaint creator             | ✅ Working              |
| New complaint           | Complaint created        | All admins                    | ✅ NEW                  |
| Task assignment         | Complaint assigned       | Specific contractor           | ✅ NEW                  |
| Urgent notice           | Emergency/warning notice | All users (topic)             | ✅ Working              |
| High priority news      | News with priority 5     | Users with newsAlerts enabled | ✅ Working              |
| Admin → Citizen chat    | Admin sends message      | Specific citizen              | ⚠️ Requires Realtime DB |
| Citizen → Admin chat    | Citizen sends message    | All admins                    | ⚠️ Requires Realtime DB |

**Legend:**

- ✅ Working - Ready to use
- ✅ NEW - Newly implemented, ready to deploy
- ⚠️ Requires Realtime DB - Enable Realtime Database first

---

## 📞 Support & Next Steps

### Enable Notification Preferences UI

**Add to Settings Screen:**

```dart
SwitchListTile(
  title: Text('Complaint Updates'),
  subtitle: Text('Get notified when complaint status changes'),
  value: _complaintUpdates,
  onChanged: (value) async {
    await NotificationService().updateNotificationPreferences(
      complaintUpdates: value,
    );
    setState(() => _complaintUpdates = value);
  },
);
```

### Monitor Token Cleanup

The `cleanupInvalidTokens` function runs daily at 2 AM to remove expired tokens.

**Check Logs:**

```
Firebase Console > Functions > cleanupInvalidTokens > Logs
Look for: "Token cleanup complete. Removed X invalid tokens"
```

### Cost Monitoring

**Cloud Functions Usage:**

- Free tier: 2M invocations/month
- Monitor: Firebase Console > Functions > Usage

**Realtime Database:**

- Free tier: 1GB storage, 10GB/month download
- Monitor: Firebase Console > Realtime Database > Usage

---

## ✅ Deployment Checklist

- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Verify all 6 base functions listed (`firebase functions:list`)
- [ ] (Optional) Enable Realtime Database for chat notifications
- [ ] (Optional) Uncomment chat functions and redeploy
- [ ] Flutter app hot restarted or rebuilt
- [ ] Test new complaint → admin notification
- [ ] Test task assignment → contractor notification
- [ ] Test complaint status → citizen notification
- [ ] Test role-based topic subscriptions (check logs)
- [ ] (Optional) Test chat notifications bidirectionally
- [ ] Monitor Function logs for errors
- [ ] Verify FCM tokens stored in Firestore
- [ ] Test multi-device support (same user, 2 devices)

---

**Deployment Date:** October 27, 2025  
**Version:** 3.0  
**Status:** Ready for Production 🚀

**Next Deploy:** Enable chat notifications after Realtime Database setup
