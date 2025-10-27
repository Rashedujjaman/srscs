# 🔔 SRSCS Notification System - Complete Guide

## 📚 Table of Contents

1. [Notification Architecture](#notification-architecture)
2. [Topics vs Direct Tokens](#topics-vs-direct-tokens)
3. [Current Flow](#current-flow)
4. [Missing Notifications](#missing-notifications)
5. [Implementation Plan](#implementation-plan)

---

## 🏗️ Notification Architecture

### **Components:**

```
┌─────────────────────────────────────────────────────────────┐
│                    NOTIFICATION SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │   Flutter    │      │   Firebase   │                   │
│  │     App      │ ←──→ │  Messaging   │                   │
│  │              │      │    (FCM)     │                   │
│  └──────────────┘      └──────────────┘                   │
│         ↓                      ↑                           │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │ Notification │      │   Cloud      │                   │
│  │   Service    │      │  Functions   │                   │
│  │   (Client)   │      │  (Server)    │                   │
│  └──────────────┘      └──────────────┘                   │
│         ↓                      ↑                           │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │   Firestore  │ ←──→ │  Realtime DB │                   │
│  │  (User Data) │      │    (Chat)    │                   │
│  └──────────────┘      └──────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Topics vs Direct Tokens

### **FCM Topics (Broadcast)**

**What are Topics?**

- Topics are like "channels" or "broadcast groups"
- Users subscribe to topics they're interested in
- When you send to a topic, ALL subscribed devices receive it
- No individual targeting needed

**Current Topics in Your App:**

| Topic Name           | Purpose                  | Who Subscribes      | Example Use Case                 |
| -------------------- | ------------------------ | ------------------- | -------------------------------- |
| `all_users`          | Broadcast to everyone    | All logged-in users | System maintenance alert         |
| `urgent_notices`     | Emergency announcements  | All users (default) | Road closure emergency           |
| `citizen_updates`    | Citizen-specific news    | Citizens only       | New complaint submission feature |
| `contractor_updates` | Contractor notifications | Contractors only    | New task assignment policy       |
| `admin_updates`      | Admin announcements      | Admins only         | System administration updates    |

**When to Use Topics:**

- ✅ System-wide announcements
- ✅ Role-based broadcasts (all citizens, all contractors)
- ✅ Emergency alerts
- ✅ News/updates for large groups

**When NOT to Use Topics:**

- ❌ User-specific notifications ("Your complaint was updated")
- ❌ Chat messages (1-to-1 communication)
- ❌ Personalized alerts

---

### **Direct Tokens (Targeted)**

**What are Direct Tokens?**

- Unique identifiers for each device
- Stored in Firestore under user documents
- Supports multiple devices per user (array of tokens)
- Precise targeting to specific users/devices

**Current Token Storage Structure:**

```json
{
  "userId": "abc123",
  "fcmTokens": [
    {
      "token": "device-1-unique-token-here",
      "platform": "android",
      "lastActive": "2025-10-27T10:00:00Z",
      "addedAt": "2025-10-20T08:00:00Z"
    },
    {
      "token": "device-2-unique-token-here",
      "platform": "ios",
      "lastActive": "2025-10-27T09:30:00Z",
      "addedAt": "2025-10-25T12:00:00Z"
    }
  ],
  "lastFcmTokenUpdate": "2025-10-27T10:00:00Z"
}
```

**When to Use Direct Tokens:**

- ✅ Complaint status updates (to the user who filed it)
- ✅ Chat messages (admin → citizen)
- ✅ Task assignments (admin → specific contractor)
- ✅ Personal notifications

---

## 🔄 Current Notification Flow

### **1. Login Flow**

```dart
User Logs In
    ↓
NotificationService.initialize() called
    ↓
Request notification permissions (iOS)
    ↓
Get FCM token from Firebase
    ↓
Save token to Firestore (fcmTokens array)
    ↓
Subscribe to topics:
    - all_users (everyone)
    - urgent_notices (everyone)
    ↓
Setup message handlers (foreground/background/terminated)
    ↓
User is now ready to receive notifications
```

### **2. Logout Flow**

```dart
User Logs Out
    ↓
NotificationService.deleteToken() called
    ↓
Remove current device's token from Firestore array
    ↓
Unsubscribe from topics (optional)
    ↓
Delete token from Firebase
    ↓
User stops receiving notifications on this device
```

### **3. Notification Delivery Flow**

**Scenario A: Complaint Status Change (Direct Token)**

```
Admin changes complaint status in Firestore
    ↓
Cloud Function: onComplaintStatusChange triggered
    ↓
Get complaint data (userId, newStatus)
    ↓
Find user in Firestore (citizens/contractors/admins)
    ↓
Get all fcmTokens array from user document
    ↓
Check user's notification preferences
    ↓
If enabled, send to ALL devices of that user
    ↓
sendEachForMulticast(tokens, message)
    ↓
Remove invalid/expired tokens from Firestore
    ↓
User receives notification on all their devices
```

**Scenario B: Urgent Notice (Topic)**

```
Admin creates urgent notice in Firestore
    ↓
Cloud Function: onUrgentNoticeCreated triggered
    ↓
Check if type is 'emergency' or 'warning'
    ↓
If yes, send to 'urgent_notices' topic
    ↓
messaging.send({ topic: 'urgent_notices', ... })
    ↓
ALL devices subscribed to topic receive notification
```

---

## ❌ Missing Notifications (Current Gaps)

### **Gap 1: New Complaint Notification (Admin/Contractor)**

**Issue:** When citizen submits complaint, admin/contractor are NOT notified

**Expected Flow:**

```
Citizen submits complaint
    ↓
Admin should receive: "📋 New Complaint #123 received"
    ↓
If assigned to contractor, contractor should receive:
"🔧 New Task Assigned: Fix pothole on Main Street"
```

**Solution:** Add Cloud Function `onComplaintCreated`

---

### **Gap 2: Chat Message Notifications (Bidirectional)**

**Issue 1:** Admin sends message → Citizen doesn't get notified

```
Admin sends chat message to Citizen
    ↓
❌ Citizen receives NO notification
    ↓
Citizen must manually check chat to see message
```

**Issue 2:** Citizen sends message → Admin doesn't get notified

```
Citizen sends chat message to Admin
    ↓
❌ Admin receives NO notification
    ↓
Admin doesn't know user is waiting for reply
```

**Solution:**

- Add Cloud Function `onChatMessage` for Realtime Database
- OR add notification trigger in chat send logic (client-side)

---

### **Gap 3: Contractor Task Assignment**

**Issue:** When admin assigns task to contractor, contractor not notified

**Expected Flow:**

```
Admin assigns complaint to Contractor
    ↓
Contractor receives: "🔧 New Task: Complaint #456"
    ↓
Notification includes: location, priority, deadline
```

**Solution:** Add Cloud Function `onComplaintAssigned`

---

### **Gap 4: Admin Not Notified of New Complaints**

**Issue:** Admin has no way to know when citizens submit complaints

**Expected Flow:**

```
Citizen submits complaint
    ↓
Admin receives: "📋 New Complaint: Pothole on Main St"
    ↓
Admin can immediately review and assign
```

**Solution:** Send to `admin_updates` topic or direct tokens to all admins

---

## 🛠️ Implementation Plan

### **Phase 1: New Complaint Notifications**

**1.1 Notify Admin on New Complaint**

- Cloud Function: `onComplaintCreated`
- Trigger: When new document added to `complaints` collection
- Send to: ALL admin users (direct tokens)
- Message: "📋 New Complaint #123: [type]"

**1.2 Notify Contractor on Task Assignment**

- Cloud Function: `onComplaintAssigned`
- Trigger: When `assignedTo` field is updated
- Send to: Specific contractor (direct token)
- Message: "🔧 New Task Assigned: [complaint title]"

---

### **Phase 2: Chat Message Notifications**

**2.1 Enable Firebase Realtime Database** (if not already enabled)

- Go to Firebase Console → Realtime Database → Create Database

**2.2 Admin → Citizen Chat Notification**

- Cloud Function: `onAdminChatReply`
- Trigger: New message in Realtime Database where `isAdmin: true`
- Send to: Citizen user (direct token)
- Message: "💬 Admin Reply: [message preview]"

**2.3 Citizen → Admin Chat Notification**

- Cloud Function: `onCitizenChatMessage`
- Trigger: New message in Realtime Database where `isAdmin: false`
- Send to: Admin (direct tokens to all admins)
- Message: "💬 New Message from Citizen: [message preview]"

---

### **Phase 3: Enhanced Topic Subscriptions**

**3.1 Role-Based Topic Subscriptions**

```dart
// Citizen subscribes to:
- all_users
- urgent_notices
- citizen_updates

// Contractor subscribes to:
- all_users
- urgent_notices
- contractor_updates

// Admin subscribes to:
- all_users
- urgent_notices
- admin_updates
```

**3.2 Update login_screen.dart**

```dart
// After login, subscribe based on role
if (userRole == UserRole.citizen) {
  await notificationService.subscribeToTopic('citizen_updates');
} else if (userRole == UserRole.contractor) {
  await notificationService.subscribeToTopic('contractor_updates');
} else if (userRole == UserRole.admin) {
  await notificationService.subscribeToTopic('admin_updates');
}
```

---

## 📝 Summary of Changes Needed

| Feature                          | Current Status   | Action Required                |
| -------------------------------- | ---------------- | ------------------------------ |
| Complaint status update          | ✅ Working       | None                           |
| Urgent notices                   | ✅ Working       | None                           |
| Multi-device support             | ✅ Working       | None                           |
| **New complaint → Admin**        | ❌ Missing       | Add Cloud Function             |
| **Task assignment → Contractor** | ❌ Missing       | Add Cloud Function             |
| **Admin → Citizen chat**         | ⚠️ Commented out | Enable Realtime DB + Uncomment |
| **Citizen → Admin chat**         | ❌ Missing       | Add Cloud Function             |
| **Role-based topics**            | ⚠️ Partial       | Update subscription logic      |

---

## 🚀 Next Steps

1. **Implement new Cloud Functions** (Phase 1)
2. **Enable Realtime Database** (Phase 2)
3. **Update topic subscriptions** (Phase 3)
4. **Test notification delivery** (All phases)
5. **Add notification preferences UI** (Optional)

---

## 📞 Notification Preference Settings

Users can control which notifications they receive:

```dart
await notificationService.updateNotificationPreferences(
  complaintUpdates: true,   // Complaint status changes
  urgentNotices: true,      // Emergency alerts
  chatMessages: true,       // Chat messages
  newsAlerts: false,        // News updates
);
```

Stored in Firestore:

```json
{
  "notificationPreferences": {
    "complaintUpdates": true,
    "urgentNotices": true,
    "chatMessages": true,
    "newsAlerts": false
  }
}
```

---

**Last Updated:** October 27, 2025  
**Version:** 2.0  
**Status:** Implementation in Progress
