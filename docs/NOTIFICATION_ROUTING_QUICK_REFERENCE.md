# Notification Routing Quick Reference

## Overview

This guide provides a quick reference for notification routing behavior in the SRSCS application.

## Notification Types & Routes

### 📋 Complaint Notifications

| Type               | From Cloud Function       | Recipient  | Route                     |
| ------------------ | ------------------------- | ---------- | ------------------------- |
| `complaint_status` | `onComplaintStatusChange` | Citizen    | `/track-complaints`       |
| `complaint_status` | `onComplaintStatusChange` | Contractor | `/contractor/tasks`       |
| `new_complaint`    | `onComplaintCreated`      | Admin      | `/admin/complaints`       |
| `task_assigned`    | `onComplaintAssigned`     | Contractor | `/contractor/task-detail` |

### 💬 Chat Notifications

| Type                            | From Cloud Function       | Recipient  | Route                | Arguments                                |
| ------------------------------- | ------------------------- | ---------- | -------------------- | ---------------------------------------- |
| `admin_chat_message`            | `onChatMessage`           | Citizen    | `/chat`              | -                                        |
| `admin_chat_message`            | `onChatMessage`           | Contractor | `/contractor/chat`   | -                                        |
| `user_chat_message`             | `onChatMessage`           | Admin      | `/admin/chat/detail` | `userId`, `userType`                     |
| `admin_contractor_chat_message` | `onContractorChatMessage` | Contractor | `/contractor/chat`   | -                                        |
| `contractor_chat_message`       | `onContractorChatMessage` | Admin      | `/admin/chat/detail` | `contractorId`, `userType: 'contractor'` |

### 📢 Notice & News Notifications

| Type            | From Cloud Function     | Recipient | Citizen Route | Contractor Route        | Admin Route        |
| --------------- | ----------------------- | --------- | ------------- | ----------------------- | ------------------ |
| `urgent_notice` | `onUrgentNoticeCreated` | All       | `/dashboard`  | `/contractor/dashboard` | `/admin/dashboard` |
| `notice`        | `onUrgentNoticeCreated` | All       | `/dashboard`  | `/contractor/dashboard` | `/admin/dashboard` |
| `emergency`     | `onUrgentNoticeCreated` | All       | `/dashboard`  | `/contractor/dashboard` | `/admin/dashboard` |
| `news`          | `onHighPriorityNews`    | All       | `/dashboard`  | `/contractor/dashboard` | `/admin/dashboard` |

## Cloud Function to Notification Type Mapping

```javascript
// functions/index.js

// 1. onComplaintStatusChange
data: {
  type: 'complaint_status',
  complaintId: string,
  status: string
}

// 2. onUrgentNoticeCreated
data: {
  type: 'urgent_notice', // or 'emergency', 'warning'
  noticeId: string,
  noticeType: string
}

// 3. onComplaintCreated
data: {
  type: 'new_complaint',
  complaintId: string,
  complaintType: string,
  priority: string
}

// 4. onComplaintAssigned
data: {
  type: 'task_assigned',
  complaintId: string,
  complaintType: string,
  priority: string
}

// 5. onChatMessage (Admin → User)
data: {
  type: 'admin_chat_message',
  userId: string,
  messageId: string
}

// 6. onChatMessage (User → Admin)
data: {
  type: 'user_chat_message',
  userId: string,
  messageId: string,
  userType: string // 'citizen' or 'contractor'
}

// 7. onContractorChatMessage (Admin → Contractor)
data: {
  type: 'admin_contractor_chat_message',
  contractorId: string,
  messageId: string
}

// 8. onContractorChatMessage (Contractor → Admin)
data: {
  type: 'contractor_chat_message',
  contractorId: string,
  messageId: string
}

// 9. onHighPriorityNews
data: {
  type: 'news',
  newsId: string
}
```

## Navigation Logic

### Role Detection

```dart
final userRole = await AuthService().getUserRole(userId);
```

### Navigation Pattern

```dart
if (userRole == UserRole.admin) {
  // Admin-specific navigation
} else if (userRole == UserRole.contractor) {
  // Contractor-specific navigation
} else if (userRole == UserRole.citizen) {
  // Citizen-specific navigation
}
```

## Adding New Notification Types

### Step 1: Add to Cloud Function (functions/index.js)

```javascript
exports.onNewEvent = functions.firestore
  .document("collection/{docId}")
  .onCreate(async (snapshot, context) => {
    // ... your logic

    const message = {
      notification: {
        title: "Your Title",
        body: "Your Body",
      },
      data: {
        type: "your_new_type", // ← Add new type here
        yourId: "some-id",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    // Send notification
  });
```

### Step 2: Handle in notification_service.dart

```dart
void _handleNotificationNavigation(Map<String, dynamic> data) async {
  // ... existing code

  switch (type) {
    // ... existing cases

    case 'your_new_type':
      if (userRole == UserRole.admin) {
        Get.toNamed('/admin/your-route');
      } else if (userRole == UserRole.contractor) {
        Get.toNamed('/contractor/your-route');
      } else if (userRole == UserRole.citizen) {
        Get.toNamed('/your-route');
      }
      break;
  }
}
```

## Testing Notifications

### 1. Using Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Create test notification
3. Select device token
4. Add custom data:
   ```json
   {
     "type": "user_chat_message",
     "userId": "test-user-id",
     "userType": "citizen"
   }
   ```
5. Send & verify navigation

### 2. Using Cloud Functions Emulator

```bash
cd functions
npm run serve
```

### 3. Using Flutter Debug Mode

- Set breakpoints in `_handleNotificationNavigation`
- Tap notification
- Verify data payload and navigation logic

## Common Issues & Solutions

### Issue 1: Notification doesn't navigate

**Solution:** Check if user is logged in and has valid role

```dart
final userId = FirebaseAuth.instance.currentUser?.uid;
if (userId == null) {
  print('❌ No user logged in');
  return;
}
```

### Issue 2: Wrong route for admin

**Solution:** Verify notification type in Cloud Function

```javascript
// Correct:
data: {
  type: "user_chat_message";
}

// Wrong:
data: {
  type: "chat_message";
}
```

### Issue 3: Arguments not passed

**Solution:** Add arguments to Get.toNamed

```dart
Get.toNamed('/admin/chat/detail', arguments: {
  'userId': senderId,
  'userType': senderType,
});
```

## Debug Logging

Enable verbose logging in notification_service.dart:

```dart
print('🧭 Notification data: $data');
print('🧭 Notification type: $type');
print('👤 User role: $userRole');
```

Check Firebase Cloud Functions logs:

```bash
firebase functions:log
```

## Best Practices

1. ✅ Always include `type` in notification data
2. ✅ Use consistent type names between Cloud Functions and Flutter
3. ✅ Include necessary IDs (userId, complaintId, etc.) for navigation
4. ✅ Test with all three user roles
5. ✅ Handle null/missing data gracefully
6. ✅ Provide fallback routes for unknown types
7. ✅ Log navigation decisions for debugging

## Reference Files

- **Cloud Functions:** `functions/index.js`
- **Notification Service:** `lib/services/notification_service.dart`
- **Routes Definition:** `lib/core/routes/app_routes.dart`
- **Auth Service:** `lib/services/auth_service.dart`
- **User Roles:** `lib/core/constants/user_roles.dart`

---

**Last Updated:** October 27, 2025  
**Version:** 2.0
