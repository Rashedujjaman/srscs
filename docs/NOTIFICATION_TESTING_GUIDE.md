# Testing Guide - Notification Navigation Update

## Overview

This guide helps you test the updated notification navigation system with role-based routing.

## Prerequisites

✅ **Before Testing:**

1. Firebase Cloud Functions deployed with latest `index.js`
2. Flutter app built with updated `notification_service.dart`
3. Test accounts for all three roles:
   - Citizen account
   - Contractor account
   - Admin account
4. Physical devices or emulators for each role
5. Firebase Console access for sending test notifications

## Test Environment Setup

### 1. Verify Cloud Functions Deployment

```bash
cd functions
firebase deploy --only functions
```

**Expected Output:**

```
✔  functions: Finished running predeploy script.
✔  functions[onComplaintStatusChange(us-central1)]: Successful update operation.
✔  functions[onUrgentNoticeCreated(us-central1)]: Successful update operation.
✔  functions[onComplaintCreated(us-central1)]: Successful update operation.
✔  functions[onComplaintAssigned(us-central1)]: Successful update operation.
✔  functions[onChatMessage(us-central1)]: Successful update operation.
✔  functions[onContractorChatMessage(us-central1)]: Successful update operation.
✔  functions[onHighPriorityNews(us-central1)]: Successful update operation.
```

### 2. Build Flutter App

```bash
# Clean previous builds
flutter clean
flutter pub get

# Run on device
flutter run
```

### 3. Prepare Test Accounts

| Role       | Email                 | Collection    |
| ---------- | --------------------- | ------------- |
| Citizen    | `citizen@test.com`    | `citizens`    |
| Contractor | `contractor@test.com` | `contractors` |
| Admin      | `admin@test.com`      | `admins`      |

## Test Cases

### Test Suite 1: Chat Notifications (Admin ← Citizen)

**Objective:** Verify admin receives chat notification from citizen and navigates to correct chat detail screen

#### Test Case 1.1: Admin Receives Message from Citizen

**Steps:**

1. Login as **Citizen** on Device A
2. Login as **Admin** on Device B
3. On Device A (Citizen):

   - Navigate to Chat screen (`/chat`)
   - Send message: "Hello Admin, I need help"
   - Wait 2-3 seconds

4. On Device B (Admin):
   - **Expected:** Notification received with title "💬 New Message from [Citizen Name]"
   - Tap notification
   - **Expected:** Navigate to `/admin/chat/detail` with citizen's userId
   - **Expected:** See the conversation with that specific citizen
   - **Expected:** Message "Hello Admin, I need help" is visible

**Verification Points:**

- ✅ Notification received on admin device
- ✅ Notification title shows citizen's name
- ✅ Tapping notification opens specific chat
- ✅ Not redirected to dashboard or chat list
- ✅ Message is visible in the chat

**Debug Logs to Check:**

```
📬 New chat message for user {citizenId}
→ User sent message, notifying all admins
📝 Message from citizen: {citizenName}
📱 Sending notification to X admin device(s)
✅ User message notification sent to X admin device(s)
```

```
🔔 Notification tapped (background)
🧭 Notification data: {type: user_chat_message, userId: {citizenId}, ...}
🧭 Notification type: user_chat_message
👤 User role: UserRole.admin
```

---

### Test Suite 2: Chat Notifications (Citizen ← Admin)

**Objective:** Verify citizen receives reply from admin and navigates to their chat screen

#### Test Case 2.1: Citizen Receives Reply from Admin

**Steps:**

1. Login as **Admin** on Device A
2. Login as **Citizen** on Device B
3. On Device A (Admin):

   - Navigate to Chat Management (`/admin/chat`)
   - Select a citizen conversation
   - Send message: "Hello, how can I help you?"
   - Wait 2-3 seconds

4. On Device B (Citizen):
   - **Expected:** Notification received with title "💬 New Message from Admin"
   - Tap notification
   - **Expected:** Navigate to `/chat` (citizen's chat screen)
   - **Expected:** Message "Hello, how can I help you?" is visible

**Verification Points:**

- ✅ Notification received on citizen device
- ✅ Notification title says "from Admin"
- ✅ Tapping notification opens citizen chat screen
- ✅ Not redirected to dashboard
- ✅ Admin's message is visible

**Debug Logs to Check:**

```
📬 New chat message for user {citizenId}
→ Admin sent message, notifying user
✅ Found user in citizen collection
📱 Found X device(s) for user {citizenId}
✅ Admin message notification sent to X device(s)
```

---

### Test Suite 3: Chat Notifications (Admin ← Contractor)

**Objective:** Verify admin receives contractor message and navigates correctly

#### Test Case 3.1: Admin Receives Message from Contractor

**Steps:**

1. Login as **Contractor** on Device A
2. Login as **Admin** on Device B
3. On Device A (Contractor):

   - Navigate to Contractor Chat (`/contractor/chat`)
   - Send message: "Task completed, please review"
   - Wait 2-3 seconds

4. On Device B (Admin):
   - **Expected:** Notification with title "💬 New Message from [Contractor Name]"
   - Tap notification
   - **Expected:** Navigate to `/admin/chat/detail` with contractor's userId
   - **Expected:** userType argument is 'contractor'
   - **Expected:** See contractor conversation
   - **Expected:** Message visible

**Verification Points:**

- ✅ Notification received on admin device
- ✅ Title shows contractor's name
- ✅ Navigation to correct chat detail
- ✅ Contractor context is preserved
- ✅ Message is visible

---

### Test Suite 4: Complaint Notifications (Admin ← Citizen)

**Objective:** Verify admin receives new complaint notification

#### Test Case 4.1: New Complaint Created

**Steps:**

1. Login as **Citizen** on Device A
2. Login as **Admin** on Device B
3. On Device A (Citizen):

   - Navigate to Submit Complaint (`/submit-complaint`)
   - Fill in complaint details:
     - Type: "Water Supply"
     - Area: "Dhanmondi 15"
     - Priority: "High"
   - Submit complaint
   - Wait 2-3 seconds

4. On Device B (Admin):
   - **Expected:** Notification "📋 New Complaint Received"
   - **Expected:** Body: "Water Supply complaint at Dhanmondi 15"
   - Tap notification
   - **Expected:** Navigate to `/admin/complaints`
   - **Expected:** New complaint visible in list

**Verification Points:**

- ✅ Notification received on admin device
- ✅ Complaint type and area in notification body
- ✅ Tapping opens admin complaints screen
- ✅ New complaint is visible
- ✅ Not redirected to citizen dashboard

**Cloud Function Logs:**

```
New complaint created: {complaintId}
Sending notification to X admin device(s)
✅ New complaint notification sent to X admin device(s)
```

---

### Test Suite 5: Complaint Status Updates (Citizen ← System)

**Objective:** Verify citizen receives status update and navigates to tracking

#### Test Case 5.1: Complaint Status Changed to In Progress

**Steps:**

1. Login as **Admin** on Device A
2. Login as **Citizen** on Device B (complaint owner)
3. On Device A (Admin):

   - Navigate to Complaints (`/admin/complaints`)
   - Select a complaint
   - Change status to "In Progress"
   - Save changes
   - Wait 2-3 seconds

4. On Device B (Citizen):
   - **Expected:** Notification "🔧 Work in Progress"
   - **Expected:** Body mentions complaint type
   - Tap notification
   - **Expected:** Navigate to `/track-complaints`
   - **Expected:** Updated status visible

**Verification Points:**

- ✅ Notification received on citizen device
- ✅ Status change reflected in notification
- ✅ Navigate to tracking screen
- ✅ Status updated in UI
- ✅ Not redirected to dashboard

---

### Test Suite 6: Task Assignment (Contractor ← Admin)

**Objective:** Verify contractor receives task assignment notification

#### Test Case 6.1: Complaint Assigned to Contractor

**Steps:**

1. Login as **Admin** on Device A
2. Login as **Contractor** on Device B
3. On Device A (Admin):

   - Navigate to Assignment (`/admin/assignment`)
   - Select a pending complaint
   - Assign to contractor
   - Save
   - Wait 2-3 seconds

4. On Device B (Contractor):
   - **Expected:** Notification "🔧 New Task Assigned"
   - **Expected:** Body shows complaint type and area
   - Tap notification
   - **Expected:** Navigate to `/contractor/task-detail`
   - **Expected:** complaintId passed as argument
   - **Expected:** Task details visible

**Verification Points:**

- ✅ Notification received on contractor device
- ✅ Task details in notification
- ✅ Navigate to task detail screen
- ✅ Correct task shown
- ✅ Not redirected to dashboard

---

### Test Suite 7: Urgent Notices (All Users)

**Objective:** Verify all user types receive urgent notice and navigate to respective dashboards

#### Test Case 7.1: Emergency Notice Created

**Steps:**

1. Login as **Citizen** on Device A
2. Login as **Contractor** on Device B
3. Login as **Admin** on Device C
4. As Admin in Firebase Console or code:

   - Create emergency notice in Firestore (`/notices`)
   - Set type: "emergency"
   - Set title: "Emergency: Water Supply Disruption"
   - Wait 2-3 seconds

5. Verify on each device:

**Device A (Citizen):**

- **Expected:** Notification "🚨 EMERGENCY ALERT"
- Tap notification
- **Expected:** Navigate to `/dashboard`

**Device B (Contractor):**

- **Expected:** Notification "🚨 EMERGENCY ALERT"
- Tap notification
- **Expected:** Navigate to `/contractor/dashboard`

**Device C (Admin):**

- **Expected:** Notification "🚨 EMERGENCY ALERT"
- Tap notification
- **Expected:** Navigate to `/admin/dashboard`

**Verification Points:**

- ✅ All three user types receive notification
- ✅ Each navigates to their respective dashboard
- ✅ Role-based routing works correctly

---

### Test Suite 8: Edge Cases

#### Test Case 8.1: Unknown Notification Type

**Steps:**

1. Send test notification from Firebase Console with custom data:
   ```json
   {
     "type": "unknown_type_xyz",
     "id": "test-123"
   }
   ```
2. Tap notification

**Expected:**

- Navigate to role-specific dashboard (fallback behavior)
- No crash or error
- Log shows: "⚠️ Unknown notification type: unknown_type_xyz"

#### Test Case 8.2: Missing User Role

**Steps:**

1. Logout from app
2. Send test notification
3. Tap notification

**Expected:**

- Log shows: "❌ No user logged in, cannot navigate"
- No navigation occurs
- No crash

#### Test Case 8.3: Missing Notification Data

**Steps:**

1. Send notification without data payload
2. Tap notification

**Expected:**

- Navigate to role-specific dashboard
- No crash
- Graceful handling

---

## Automated Testing Script

### Test Notification Sender (Node.js)

Create `test-notifications.js`:

```javascript
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccount.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Test 1: Citizen → Admin Chat
async function testCitizenToAdminChat(citizenId, adminToken) {
  const message = {
    notification: {
      title: "💬 New Message from Test Citizen",
      body: "Test message content",
    },
    data: {
      type: "user_chat_message",
      userId: citizenId,
      userType: "citizen",
      messageId: "test-msg-001",
    },
    token: adminToken,
  };

  const response = await admin.messaging().send(message);
  console.log("✅ Test notification sent:", response);
}

// Test 2: Admin → Citizen Chat
async function testAdminToCitizenChat(citizenId, citizenToken) {
  const message = {
    notification: {
      title: "💬 New Message from Admin",
      body: "Test admin reply",
    },
    data: {
      type: "admin_chat_message",
      userId: citizenId,
      messageId: "test-msg-002",
    },
    token: citizenToken,
  };

  const response = await admin.messaging().send(message);
  console.log("✅ Test notification sent:", response);
}

// Run tests
(async () => {
  try {
    // Get FCM tokens from Firestore
    const adminDoc = await admin
      .firestore()
      .collection("admins")
      .doc("ADMIN_ID")
      .get();
    const citizenDoc = await admin
      .firestore()
      .collection("citizens")
      .doc("CITIZEN_ID")
      .get();

    const adminToken = adminDoc.data().fcmTokens[0].token;
    const citizenToken = citizenDoc.data().fcmTokens[0].token;

    console.log("Testing Citizen → Admin Chat...");
    await testCitizenToAdminChat("CITIZEN_ID", adminToken);

    console.log("\nTesting Admin → Citizen Chat...");
    await testAdminToCitizenChat("CITIZEN_ID", citizenToken);

    console.log("\n✅ All tests completed!");
  } catch (error) {
    console.error("❌ Test failed:", error);
  }
})();
```

**Run:**

```bash
node test-notifications.js
```

---

## Manual Testing Checklist

### Pre-Deployment Checklist

- [ ] Cloud Functions deployed
- [ ] Flutter app built with changes
- [ ] Test accounts created for all roles
- [ ] FCM tokens verified in Firestore
- [ ] Notification permissions enabled on devices

### Citizen Tests

- [ ] Receives complaint status update → Routes to `/track-complaints`
- [ ] Receives admin chat reply → Routes to `/chat`
- [ ] Receives urgent notice → Routes to `/dashboard`
- [ ] Receives news alert → Routes to `/dashboard`

### Contractor Tests

- [ ] Receives task assignment → Routes to `/contractor/task-detail`
- [ ] Receives complaint status update → Routes to `/contractor/tasks`
- [ ] Receives admin chat message → Routes to `/contractor/chat`
- [ ] Receives urgent notice → Routes to `/contractor/dashboard`

### Admin Tests

- [ ] Receives new complaint → Routes to `/admin/complaints`
- [ ] Receives citizen chat message → Routes to `/admin/chat/detail` (citizen)
- [ ] Receives contractor chat message → Routes to `/admin/chat/detail` (contractor)
- [ ] Receives urgent notice → Routes to `/admin/dashboard`

### Edge Cases

- [ ] Unknown notification type → Routes to dashboard
- [ ] No user logged in → No navigation, logs error
- [ ] Missing data fields → Graceful fallback
- [ ] App in background → Correct navigation
- [ ] App terminated → Correct navigation on tap

---

## Debugging Guide

### Enable Debug Logging

In `notification_service.dart`, verify these logs are present:

```dart
print('🧭 Notification data: $data');
print('🧭 Notification type: $type');
print('👤 User role: $userRole');
```

### Check Cloud Functions Logs

```bash
# Real-time logs
firebase functions:log --only onChatMessage

# Filter by time
firebase functions:log --only onChatMessage --since 1h
```

### Check Firestore FCM Tokens

In Firebase Console:

1. Go to Firestore Database
2. Navigate to `admins/{userId}`
3. Check `fcmTokens` array:
   ```json
   [
     {
       "token": "fcm_token_here",
       "platform": "android",
       "lastActive": Timestamp,
       "addedAt": Timestamp
     }
   ]
   ```

### Verify Notification Delivery

In Firebase Console:

1. Cloud Messaging → Send test message
2. Add FCM token
3. Add data payload:
   ```json
   {
     "type": "user_chat_message",
     "userId": "test-user-id",
     "userType": "citizen"
   }
   ```
4. Send & verify

---

## Test Results Template

### Test Session: [Date]

**Environment:**

- Flutter Version: **\_\_**
- Firebase SDK Version: **\_\_**
- Test Devices: **\_\_**

**Test Results:**

| Test Case                     | Status  | Notes |
| ----------------------------- | ------- | ----- |
| Chat: Citizen → Admin         | ✅ / ❌ |       |
| Chat: Admin → Citizen         | ✅ / ❌ |       |
| Chat: Contractor → Admin      | ✅ / ❌ |       |
| Chat: Admin → Contractor      | ✅ / ❌ |       |
| Complaint: New (Admin)        | ✅ / ❌ |       |
| Complaint: Status (Citizen)   | ✅ / ❌ |       |
| Task: Assignment (Contractor) | ✅ / ❌ |       |
| Notice: Urgent (All)          | ✅ / ❌ |       |
| Edge: Unknown Type            | ✅ / ❌ |       |
| Edge: No User                 | ✅ / ❌ |       |

**Issues Found:**

1.
2.
3.

**Overall Status:** ✅ PASS / ❌ FAIL

---

## Production Rollout Plan

1. **Phase 1: Internal Testing**

   - Test with development Firebase project
   - Verify all test cases pass
   - Fix any issues found

2. **Phase 2: Beta Testing**

   - Deploy to staging environment
   - Test with beta users (1-2 from each role)
   - Collect feedback

3. **Phase 3: Gradual Rollout**

   - Deploy to 10% of users
   - Monitor logs for errors
   - Increase to 50% if stable
   - Full rollout

4. **Phase 4: Post-Deployment**
   - Monitor crash reports
   - Check navigation analytics
   - Gather user feedback
   - Address any issues

---

**Testing Version:** 1.0  
**Last Updated:** October 27, 2025  
**Next Review:** After deployment
