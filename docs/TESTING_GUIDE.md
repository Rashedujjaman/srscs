# 🧪 Chat Notification Testing Guide

## 📋 Overview

This guide provides step-by-step testing scenarios to verify that the chat notification viewing status implementation is working correctly.

---

## 🎯 Pre-Testing Checklist

Before testing, ensure:

- ✅ Cloud Functions are deployed (`firebase deploy --only functions`)
- ✅ Flutter app is running with latest code
- ✅ Firebase Realtime Database is accessible
- ✅ At least 2 test accounts ready (1 citizen/contractor, 1 admin)
- ✅ Devices can receive push notifications

---

## 🧪 Test Scenarios

### **Test 1: Citizen Active Chat - No Notification**

**Objective:** Verify citizen doesn't get notification when viewing chat

**Steps:**

1. **Device A (Citizen):**
   - Login as citizen
   - Navigate to Chat screen
   - Keep chat screen open
2. **Device B (Admin):**
   - Login as admin
   - Open chat with that citizen
   - Send a message: "Test message from admin"
3. **Expected Results:**
   - ✅ Device A shows message immediately in chat
   - ✅ Device A does NOT receive push notification
   - ✅ Firebase Console: `chats/{userId}/chatStatus/isViewing = true`
   - ✅ Cloud Function logs: "User is currently viewing chat, skipping notification"

**Status:** [ ] PASS [ ] FAIL

---

### **Test 2: Citizen Closed Chat - Notification Sent**

**Objective:** Verify citizen gets notification when NOT viewing chat

**Steps:**

1. **Device A (Citizen):**
   - Login as citizen
   - Navigate to Dashboard or any screen (NOT chat)
2. **Device B (Admin):**
   - Login as admin
   - Open chat with that citizen
   - Send a message: "You should get this notification"
3. **Expected Results:**
   - ✅ Device A receives push notification
   - ✅ Notification shows: "💬 New Message from Admin"
   - ✅ Tapping notification opens chat screen
   - ✅ Message visible in chat
   - ✅ Firebase Console: `chats/{userId}/chatStatus/isViewing = false` (or null)

**Status:** [ ] PASS [ ] FAIL

---

### **Test 3: Citizen Minimizes App - Notification Sent**

**Objective:** Verify lifecycle handling when app goes to background

**Steps:**

1. **Device A (Citizen):**
   - Login as citizen
   - Open Chat screen
   - Press HOME button (minimize app)
2. **Device B (Admin):**
   - Send a message: "App is in background"
3. **Expected Results:**

   - ✅ Device A receives push notification (even though chat was open)
   - ✅ Firebase Console: `chats/{userId}/chatStatus/isViewing = false`
   - ✅ Cloud Function logs: Notification sent

4. **Continue Test:**
   - Tap notification to reopen app
   - Check Firebase Console again
   - ✅ Firebase Console: `chats/{userId}/chatStatus/isViewing = true`

**Status:** [ ] PASS [ ] FAIL

---

### **Test 4: Admin Active Chat - No Notification**

**Objective:** Verify admin doesn't get notification when viewing chat

**Steps:**

1. **Device A (Admin):**
   - Login as admin
   - Navigate to Chat List
   - Open chat with a citizen
   - Keep chat screen open
2. **Device B (Citizen):**
   - Login as citizen
   - Open Chat screen
   - Send a message: "Reply from citizen"
3. **Expected Results:**
   - ✅ Device A shows message immediately in chat
   - ✅ Device A does NOT receive push notification
   - ✅ Firebase Console: `admin_chat_status/{userId}/isViewing = true`
   - ✅ Cloud Function logs: "Admin is currently viewing chat with {userId}, skipping notification"

**Status:** [ ] PASS [ ] FAIL

---

### **Test 5: Admin Closed Chat - Notification Sent**

**Objective:** Verify admin gets notification when NOT viewing chat

**Steps:**

1. **Device A (Admin):**
   - Login as admin
   - Navigate to Dashboard (NOT in chat)
2. **Device B (Citizen):**
   - Login as citizen
   - Open Chat screen
   - Send a message: "Admin should get notification"
3. **Expected Results:**
   - ✅ Device A receives push notification
   - ✅ Notification shows: "💬 New Message from [Citizen Name]"
   - ✅ Tapping notification opens admin chat list or chat detail
   - ✅ Firebase Console: `admin_chat_status/{userId}/isViewing = false` (or null)

**Status:** [ ] PASS [ ] FAIL

---

### **Test 6: Contractor Active Chat - No Notification**

**Objective:** Verify contractor doesn't get notification when viewing chat

**Steps:**

1. **Device A (Contractor):**
   - Login as contractor
   - Navigate to Chat screen
   - Keep chat screen open
2. **Device B (Admin):**
   - Login as admin
   - Open chat with that contractor
   - Send a message: "Task update from admin"
3. **Expected Results:**
   - ✅ Device A shows message immediately in chat
   - ✅ Device A does NOT receive push notification
   - ✅ Firebase Console: `contractor_chats/{contractorId}/chatStatus/isViewing = true`
   - ✅ Cloud Function logs: "Contractor is currently viewing chat, skipping notification"

**Status:** [ ] PASS [ ] FAIL

---

### **Test 7: Contractor Closed Chat - Notification Sent**

**Objective:** Verify contractor gets notification when NOT viewing chat

**Steps:**

1. **Device A (Contractor):**
   - Login as contractor
   - Navigate to Tasks or Dashboard (NOT chat)
2. **Device B (Admin):**
   - Login as admin
   - Open chat with that contractor
   - Send a message: "Contractor should get this"
3. **Expected Results:**
   - ✅ Device A receives push notification
   - ✅ Notification shows: "💬 New Message from Admin"
   - ✅ Firebase Console: `contractor_chats/{contractorId}/chatStatus/isViewing = false` (or null)

**Status:** [ ] PASS [ ] FAIL

---

### **Test 8: Admin Switches Between Chats**

**Objective:** Verify viewing status updates correctly when switching chats

**Steps:**

1. **Device A (Admin):**
   - Login as admin
   - Open chat with Citizen A
   - Check Firebase: `admin_chat_status/{citizenA_id}/isViewing = true`
2. **Device B (Citizen B):**
   - Send message to admin
3. **Expected Results:**
   - ✅ Device A receives notification (not viewing Citizen B's chat)
4. **Continue:**
   - Device A: Back to chat list
   - Device A: Open chat with Citizen B
   - Check Firebase: `admin_chat_status/{citizenB_id}/isViewing = true`
   - Check Firebase: `admin_chat_status/{citizenA_id}/isViewing = false` (or deleted)

**Status:** [ ] PASS [ ] FAIL

---

### **Test 9: Rapid Open/Close**

**Objective:** Verify system handles rapid status changes

**Steps:**

1. **Device A (Citizen):**
   - Open chat screen
   - Wait 2 seconds
   - Close chat screen
   - Wait 2 seconds
   - Open chat screen again
   - Wait 2 seconds
   - Close chat screen
2. **Device B (Admin):**
   - Send message when chat is OPEN
   - Send message when chat is CLOSED
3. **Expected Results:**
   - ✅ No notification when chat was open
   - ✅ Notification received when chat was closed
   - ✅ No database errors
   - ✅ Viewing status updates correctly each time

**Status:** [ ] PASS [ ] FAIL

---

### **Test 10: Multiple Admins**

**Objective:** Verify system works with multiple admins

**Steps:**

1. **Device A (Admin 1):**
   - Login as admin
   - Open chat with citizen
   - Keep chat screen open
2. **Device B (Admin 2):**
   - Login as different admin
   - Navigate to dashboard (NOT in chat)
3. **Device C (Citizen):**
   - Send a message
4. **Expected Results:**
   - ✅ Device A (Admin 1) does NOT get notification (viewing chat)
   - ✅ Device B (Admin 2) DOES get notification (not viewing)
   - ✅ Firebase Console: Only one admin has `isViewing = true`

**Status:** [ ] PASS [ ] FAIL

---

## 📊 Monitoring Tools

### **Firebase Console - Realtime Database**

**Path to check:**

```
Firebase Console → Realtime Database → Data

Check these paths:
- chats/{userId}/chatStatus/isViewing
- contractor_chats/{contractorId}/chatStatus/isViewing
- admin_chat_status/{userId}/isViewing
```

**Expected values:**

- `true` = User is viewing chat
- `false` or `null` = User is not viewing chat
- `lastSeen` = Timestamp of last status update

### **Firebase Console - Cloud Functions Logs**

**Path to check:**

```
Firebase Console → Functions → Logs

Filter by function name:
- onChatMessage
- onContractorChatMessage
```

**Look for these log messages:**

```
✅ "User is currently viewing chat, skipping notification"
✅ "Admin is currently viewing chat with {userId}, skipping notification"
✅ "Contractor is currently viewing chat, skipping notification"
📬 "Sending notification to [number] devices"
```

### **Flutter Debug Console**

**Print statements to look for:**

```
📱 Chat viewing status set: true (UserRole.citizen)
📱 Chat viewing status set: false (UserRole.citizen)
📱 Admin viewing status set for abc123: true
📱 Admin viewing status set for abc123: false
❌ Error setting chat viewing status: [error]
```

---

## 🐛 Troubleshooting

### **Issue: Still getting notifications while chatting**

**Possible causes:**

1. Viewing status not set to true
2. Cloud Functions not deployed
3. Database permissions issue

**Debug steps:**

1. Check Firebase Console → Realtime Database
   - Is `isViewing` set to `true`?
   - Does the path exist?
2. Check Cloud Function logs
   - Are functions checking viewing status?
   - Are there any errors?
3. Check Flutter debug console
   - Are status updates being printed?
   - Are there any errors?

### **Issue: Not getting notifications after closing chat**

**Possible causes:**

1. Viewing status not cleared on dispose
2. App lifecycle not handled correctly

**Debug steps:**

1. Check Firebase Console → Realtime Database
   - Is `isViewing` set to `false` or deleted?
2. Check Flutter code
   - Is `dispose()` calling `_setChatViewingStatus(false)`?
   - Is `WidgetsBindingObserver` properly implemented?

### **Issue: Notifications inconsistent**

**Possible causes:**

1. App lifecycle state changes not handled
2. Multiple instances of chat screen

**Debug steps:**

1. Check `didChangeAppLifecycleState` implementation
2. Verify only one chat screen is open at a time
3. Check for duplicate database writes

---

## 📝 Test Results Template

### **Test Environment:**

- **Date:** ******\_\_\_******
- **Flutter Version:** ******\_\_\_******
- **Firebase SDK Version:** ******\_\_\_******
- **Test Devices:**
  - Device A: ******\_\_\_******
  - Device B: ******\_\_\_******
  - Device C: ******\_\_\_******

### **Test Results:**

| Test # | Scenario               | Result            | Notes |
| ------ | ---------------------- | ----------------- | ----- |
| 1      | Citizen Active Chat    | [ ] PASS [ ] FAIL |       |
| 2      | Citizen Closed Chat    | [ ] PASS [ ] FAIL |       |
| 3      | Citizen Minimizes App  | [ ] PASS [ ] FAIL |       |
| 4      | Admin Active Chat      | [ ] PASS [ ] FAIL |       |
| 5      | Admin Closed Chat      | [ ] PASS [ ] FAIL |       |
| 6      | Contractor Active Chat | [ ] PASS [ ] FAIL |       |
| 7      | Contractor Closed Chat | [ ] PASS [ ] FAIL |       |
| 8      | Admin Switches Chats   | [ ] PASS [ ] FAIL |       |
| 9      | Rapid Open/Close       | [ ] PASS [ ] FAIL |       |
| 10     | Multiple Admins        | [ ] PASS [ ] FAIL |       |

### **Overall Status:**

- [ ] All tests passed - Ready for production
- [ ] Some tests failed - Needs fixes
- [ ] Critical issues found - Rollback required

### **Notes:**

---

---

---

---

**Last Updated:** October 27, 2025  
**Version:** 1.0  
**Status:** Ready for Testing 🧪
