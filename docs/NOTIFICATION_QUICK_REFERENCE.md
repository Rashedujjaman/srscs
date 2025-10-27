# 🔔 Notification Topics & Flow - Quick Reference

## 📌 What You Asked About

### 1️⃣ **Topic Subscribe/Unsubscribe Purpose**

**Topics = Broadcast Channels**

- Like subscribing to a TV channel
- When you send to a topic, EVERYONE subscribed receives it
- No need to target individual devices

**Your Current Topics:**

```dart
await notificationService.subscribeToTopic('all_users');        // Everyone
await notificationService.subscribeToTopic('urgent_notices');   // Emergencies
await notificationService.subscribeToTopic('citizen_updates');  // Citizens only
await notificationService.subscribeToTopic('contractor_updates'); // Contractors only
await notificationService.subscribeToTopic('admin_updates');    // Admins only
```

**Why Subscribe on Login?**

- User needs to hear announcements
- System-wide alerts reach all devices
- Role-specific news (e.g., "New feature for contractors")

**Why Unsubscribe on Logout?**

- Stop getting notifications after logout
- Device no longer belongs to that user
- Privacy & security (no notifications for wrong user)

---

### 2️⃣ **Notification Flow Diagram**

```
┌─────────────────────────────────────────────────────────────┐
│                   NOTIFICATION FLOW                         │
└─────────────────────────────────────────────────────────────┘

📱 USER LOGS IN
    ↓
✅ NotificationService.initialize()
    ↓
🔑 Get FCM Token (unique device ID)
    ↓
💾 Save to Firestore: fcmTokens array
    ↓
📢 Subscribe to Topics:
    • all_users
    • urgent_notices
    • [role]_updates (citizen/contractor/admin)
    ↓
🎧 Setup Message Handlers (foreground/background/terminated)
    ↓
✅ READY TO RECEIVE NOTIFICATIONS

─────────────────────────────────────────────────────────────

📋 ACTION HAPPENS (e.g., Complaint Status Changed)
    ↓
🔥 Firestore/Realtime DB Updated
    ↓
⚡ Cloud Function Triggered
    ↓
🔍 Find User(s) to Notify
    ↓
📊 Check Notification Preferences
    ↓
🎯 Get FCM Tokens from Firestore
    ↓
📤 Send via Firebase Cloud Messaging (FCM)
    ↓
📱 User's Device(s) Receive Notification
    ↓
🔔 Notification Displayed (with sound/vibration)
    ↓
👆 User Taps Notification
    ↓
🧭 Navigate to Relevant Screen

─────────────────────────────────────────────────────────────

🚪 USER LOGS OUT
    ↓
📢 Unsubscribe from All Topics
    ↓
🗑️ Delete Token from Firestore (current device only)
    ↓
❌ STOP RECEIVING NOTIFICATIONS
```

---

### 3️⃣ **Missing Notifications (Fixed Now!)**

| Notification                     | Status Before  | Status After                  | How It Works                                              |
| -------------------------------- | -------------- | ----------------------------- | --------------------------------------------------------- |
| **New Complaint → Admin**        | ❌ Not working | ✅ Fixed                      | Cloud Function sends to ALL admins when complaint created |
| **Task Assignment → Contractor** | ❌ Not working | ✅ Fixed                      | Cloud Function sends to specific contractor when assigned |
| **Admin → Citizen Chat**         | ❌ Not working | ⚠️ Need to enable Realtime DB | Cloud Function triggers on admin message                  |
| **Citizen → Admin Chat**         | ❌ Not working | ⚠️ Need to enable Realtime DB | Cloud Function sends to all admins                        |

---

## 🎯 Notification Types in Your App

### **A. Direct Token Notifications** (Targeted)

**Use Case:** Specific user needs to know something personal

| Scenario                 | Who Receives        | Notification                            |
| ------------------------ | ------------------- | --------------------------------------- |
| Complaint status changed | Complaint creator   | "🔧 Your complaint is In Progress"      |
| Task assigned            | Specific contractor | "🔧 New Task: Fix pothole on Main St"   |
| Admin replies in chat    | Specific citizen    | "💬 Admin Reply: We're looking into it" |
| Citizen sends message    | All admins          | "💬 New Message from John: Need help"   |

**How it works:**

```javascript
// Cloud Function gets user's tokens
const fcmTokens = userData.fcmTokens || [];
const tokens = fcmTokens.map((t) => t.token);

// Send to all user's devices
await admin.messaging().sendEachForMulticast({
  tokens: tokens,
  notification: { title, body },
  data: { type, id },
});
```

---

### **B. Topic Notifications** (Broadcast)

**Use Case:** Announcement to many users at once

| Scenario                         | Topic                | Who Receives     |
| -------------------------------- | -------------------- | ---------------- |
| System maintenance               | `all_users`          | Everyone         |
| Road closure emergency           | `urgent_notices`     | Everyone         |
| New complaint submission feature | `citizen_updates`    | Citizens only    |
| New contractor app released      | `contractor_updates` | Contractors only |
| System admin update              | `admin_updates`      | Admins only      |

**How it works:**

```javascript
// Send to topic (no need to find individual tokens)
await admin.messaging().send({
  notification: { title, body },
  topic: "urgent_notices",
});

// All devices subscribed to 'urgent_notices' receive it
```

---

## 🔄 Complete Notification Implementation

### **NEW Cloud Functions Added:**

#### 1. `onComplaintCreated` - Notify Admin

```javascript
// Triggers when: New complaint submitted
// Sends to: ALL admins
// Message: "📋 New Complaint Received: [type] at [location]"
```

#### 2. `onComplaintAssigned` - Notify Contractor

```javascript
// Triggers when: Admin assigns complaint to contractor
// Sends to: Specific contractor
// Message: "🔧 New Task Assigned: [type] at [location]"
```

#### 3. `onAdminChatReply` - Notify Citizen (Requires Realtime DB)

```javascript
// Triggers when: Admin sends chat message (isAdmin: true)
// Sends to: Specific citizen
// Message: "💬 New Message from Admin: [message preview]"
```

#### 4. `onCitizenChatMessage` - Notify Admin (Requires Realtime DB)

```javascript
// Triggers when: Citizen sends chat message (isAdmin: false)
// Sends to: ALL admins
// Message: "💬 New Message from [Name]: [message preview]"
```

### **Updated Flutter Code:**

#### Login Screen - Role-Based Subscriptions

```dart
// Subscribe to common topics
await notificationService.subscribeToTopic('all_users');
await notificationService.subscribeToTopic('urgent_notices');

// Subscribe to role-specific topic
switch (userRole) {
  case UserRole.citizen:
    await notificationService.subscribeToTopic('citizen_updates');
    break;
  case UserRole.contractor:
    await notificationService.subscribeToTopic('contractor_updates');
    break;
  case UserRole.admin:
    await notificationService.subscribeToTopic('admin_updates');
    break;
}
```

#### Logout - Topic Cleanup

```dart
// Unsubscribe from all topics
await notificationService.unsubscribeFromTopic('all_users');
await notificationService.unsubscribeFromTopic('urgent_notices');
await notificationService.unsubscribeFromTopic('citizen_updates');
await notificationService.unsubscribeFromTopic('contractor_updates');
await notificationService.unsubscribeFromTopic('admin_updates');

// Delete token
await notificationService.deleteToken();
```

---

## 🚀 What You Need to Do Next

### **Step 1: Deploy Cloud Functions** ✅ READY

```powershell
cd functions
firebase deploy --only functions
```

**This will add:**

- ✅ `onComplaintCreated` - Admin gets notified on new complaints
- ✅ `onComplaintAssigned` - Contractor gets notified on task assignment

---

### **Step 2: Test Without Chat** ✅ READY

1. **Test New Complaint:**

   - Login as Citizen → Submit complaint
   - Login as Admin → Should receive notification

2. **Test Task Assignment:**

   - Login as Admin → Assign complaint to contractor
   - Login as Contractor → Should receive notification

3. **Test Topics:**
   - Check logs after login for: `✅ Subscribed to [topic] topic`

---

### **Step 3: Enable Chat Notifications** ⚠️ OPTIONAL

**Only if you want chat notifications:**

1. Enable Realtime Database in Firebase Console
2. Set security rules for chat
3. Uncomment chat functions in `functions/index.js`
4. Redeploy: `firebase deploy --only functions`

**If you DON'T need chat notifications:**

- Skip this step
- Everything else still works perfectly

---

## 📊 Notification Summary

### **Working Now:**

✅ Complaint status updates → Citizen  
✅ Urgent notices → All users (topic)  
✅ High priority news → Opted-in users  
✅ Multi-device support  
✅ Token cleanup on logout  
✅ Token re-registration on login

### **NEW (After Deploy):**

🆕 New complaint → Admin  
🆕 Task assignment → Contractor  
🆕 Role-based topics

### **Optional (Need Realtime DB):**

⚠️ Admin → Citizen chat  
⚠️ Citizen → Admin chat

---

## 📞 Quick Troubleshooting

**No notification received?**

1. Check FCM token exists in Firestore (`fcmTokens` array)
2. Check notification permissions enabled on device
3. Check Cloud Function logs in Firebase Console
4. Verify topic subscriptions in app logs

**Chat notifications not working?**

1. Is Realtime Database enabled? (Firebase Console)
2. Are chat functions uncommented? (functions/index.js)
3. Is message structure correct? (message, timestamp, isAdmin)
4. Check Function logs for errors

**Topics not working?**

1. Check spelling: `all_users` not `allUsers`
2. Verify subscription logs: `✅ Subscribed to [topic] topic`
3. Test with Firebase Console → Cloud Messaging → Send test to topic

---

**Documentation Created:**

- ✅ `NOTIFICATION_SYSTEM_GUIDE.md` - Complete technical guide
- ✅ `NOTIFICATION_DEPLOYMENT_GUIDE.md` - Step-by-step deployment
- ✅ `NOTIFICATION_QUICK_REFERENCE.md` - This document

**Ready to deploy!** 🚀
