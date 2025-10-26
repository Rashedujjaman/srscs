# Multi-Device Notification Support

## Overview

The notification service has been updated to support multiple devices per user account. Each user can now receive notifications on all their logged-in devices.

## Changes Made

### 1. Token Storage Structure

**Old Structure (Single Device):**

```json
{
  "userId": "abc123",
  "fcmToken": "single-token-here",
  "fcmTokenUpdatedAt": "timestamp"
}
```

**New Structure (Multiple Devices):**

```json
{
  "userId": "abc123",
  "fcmTokens": [
    {
      "token": "device-1-token",
      "platform": "android",
      "lastActive": "timestamp",
      "addedAt": "timestamp"
    },
    {
      "token": "device-2-token",
      "platform": "ios",
      "lastActive": "timestamp",
      "addedAt": "timestamp"
    }
  ],
  "fcmToken": "device-2-token", // Latest token (backward compatibility)
  "fcmTokenUpdatedAt": "timestamp"
}
```

### 2. Client-Side Updates

#### Token Management

- ✅ Tokens are stored in an array (`fcmTokens`)
- ✅ Each token entry includes platform and timestamps
- ✅ Duplicate tokens are prevented
- ✅ Last active timestamp is updated on each login
- ✅ Old tokens (30+ days inactive) are automatically cleaned up
- ✅ On logout, only the current device's token is removed

#### Methods Added

- `cleanupInactiveTokens()` - Removes tokens inactive for 30+ days
- Updated `deleteToken()` - Removes only current device token on logout
- Updated `_saveFCMTokenToFirestore()` - Manages token array

## Backend Implementation

### Option 1: Firebase Cloud Functions (Recommended)

Create a Cloud Function to send notifications to all user devices:

```javascript
// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Send notification to all devices of a user
 * Triggered when complaint status changes
 */
exports.sendComplaintStatusUpdate = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Only send if status changed
    if (newData.status === oldData.status) {
      return null;
    }

    const userId = newData.userId;
    const complaintId = context.params.complaintId;

    // Determine user collection based on role
    let userDoc;
    const citizenDoc = await admin
      .firestore()
      .collection("citizens")
      .doc(userId)
      .get();

    if (citizenDoc.exists) {
      userDoc = citizenDoc;
    } else {
      const contractorDoc = await admin
        .firestore()
        .collection("contractors")
        .doc(userId)
        .get();
      if (contractorDoc.exists) {
        userDoc = contractorDoc;
      } else {
        const adminDoc = await admin
          .firestore()
          .collection("admins")
          .doc(userId)
          .get();
        userDoc = adminDoc;
      }
    }

    if (!userDoc || !userDoc.exists) {
      console.log("User not found:", userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];

    if (fcmTokens.length === 0) {
      console.log("No FCM tokens found for user:", userId);
      return null;
    }

    // Extract just the token strings
    const tokens = fcmTokens.map((t) => t.token).filter((t) => t);

    if (tokens.length === 0) {
      console.log("No valid tokens found for user:", userId);
      return null;
    }

    // Create notification message
    const message = {
      notification: {
        title: "🔔 Complaint Status Updated",
        body: `Your complaint status has been updated to: ${newData.status}`,
      },
      data: {
        type: "complaint_status",
        complaintId: complaintId,
        status: newData.status,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    // Send to all devices
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });

      console.log(`Successfully sent to ${response.successCount} devices`);
      console.log(`Failed to send to ${response.failureCount} devices`);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log("Failed token:", tokens[idx], resp.error);
            invalidTokens.push(fcmTokens[idx]);
          }
        });

        // Remove invalid tokens from Firestore
        if (invalidTokens.length > 0) {
          const validTokens = fcmTokens.filter(
            (t) => !invalidTokens.includes(t)
          );
          await userDoc.ref.update({ fcmTokens: validTokens });
          console.log(`Removed ${invalidTokens.length} invalid tokens`);
        }
      }

      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

/**
 * Send chat notification to all user devices
 */
exports.sendChatNotification = functions.database
  .ref("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    const chatId = context.params.chatId;

    // Extract userId from chatId (format: "userId" or "citizen-admin-userId")
    let userId = chatId;
    if (chatId.includes("-")) {
      const parts = chatId.split("-");
      userId = parts[parts.length - 1];
    }

    // Don't notify the sender
    if (message.senderId === userId) {
      return null;
    }

    // Get user's FCM tokens (check all collections)
    let userDoc;
    const collections = ["citizens", "contractors", "admins"];

    for (const collection of collections) {
      const doc = await admin
        .firestore()
        .collection(collection)
        .doc(userId)
        .get();
      if (doc.exists) {
        userDoc = doc;
        break;
      }
    }

    if (!userDoc || !userDoc.exists) {
      console.log("User not found:", userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];
    const tokens = fcmTokens.map((t) => t.token).filter((t) => t);

    if (tokens.length === 0) {
      console.log("No tokens found for user:", userId);
      return null;
    }

    // Send notification
    const notificationMessage = {
      notification: {
        title: "💬 New Message",
        body: message.senderName + ": " + message.message.substring(0, 50),
      },
      data: {
        type: "chat_message",
        chatId: chatId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...notificationMessage,
      });

      console.log(`Chat notification sent to ${response.successCount} devices`);
      return response;
    } catch (error) {
      console.error("Error sending chat notification:", error);
      return null;
    }
  });
```

### Option 2: Manual Server-Side Implementation

If you're using a custom backend, here's how to send to multiple devices:

```dart
// Example Dart/Flutter Admin SDK usage
Future<void> sendNotificationToUser(String userId, Map<String, String> notification) async {
  // Get user document from appropriate collection
  DocumentSnapshot userDoc = await getUserDocument(userId);

  if (!userDoc.exists) return;

  final data = userDoc.data() as Map<String, dynamic>;
  final fcmTokens = data['fcmTokens'] as List<dynamic>? ?? [];

  // Extract token strings
  final tokens = fcmTokens
      .map((t) => t['token'] as String?)
      .where((t) => t != null)
      .cast<String>()
      .toList();

  if (tokens.isEmpty) {
    print('No tokens found for user: $userId');
    return;
  }

  // Send using your preferred method (HTTP API, Admin SDK, etc.)
  for (final token in tokens) {
    await sendFCMNotification(token, notification);
  }
}
```

### Option 3: Using FCM HTTP v1 API

```bash
# Send to multiple tokens
curl -X POST \
  'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": {
      "tokens": ["token1", "token2", "token3"],
      "notification": {
        "title": "Complaint Updated",
        "body": "Your complaint status has changed"
      },
      "data": {
        "type": "complaint_status",
        "complaintId": "123"
      }
    }
  }'
```

## Testing Multi-Device Support

1. **Login on Device 1**
   - Check Firestore: Should see 1 token in `fcmTokens` array
2. **Login on Device 2** (same account)
   - Check Firestore: Should see 2 tokens in `fcmTokens` array
3. **Change Complaint Status** (as admin)
   - Both devices should receive notification
4. **Logout from Device 1**

   - Check Firestore: Should see only 1 token remaining (Device 2)
   - Device 2 should still receive notifications

5. **Wait 30+ days with inactive device**
   - Token should be automatically cleaned up on next login

## Migration Steps

If you have existing users with the old single-token structure:

1. **No action required** - The new code is backward compatible
2. Existing `fcmToken` field will remain for backward compatibility
3. New `fcmTokens` array will be created on next login
4. Old Cloud Functions should continue to work with `fcmToken` field
5. Update Cloud Functions gradually to use `fcmTokens` array

## Firestore Security Rules

Update your Firestore security rules to allow the array structure:

```javascript
match /citizens/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  // Allow updating FCM tokens
  allow update: if request.auth.uid == userId
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['fcmToken', 'fcmTokens', 'fcmTokenUpdatedAt']);
}

// Same for contractors and admins collections
```

## Benefits

✅ **Multiple Device Support** - Users receive notifications on all devices
✅ **Automatic Cleanup** - Old/inactive tokens removed after 30 days
✅ **Selective Logout** - Logging out on one device doesn't affect others
✅ **Backward Compatible** - Works with existing single-token implementations
✅ **Token Validation** - Invalid tokens automatically removed
✅ **Platform Tracking** - Know which devices are Android/iOS

## Troubleshooting

**Notifications only going to one device?**

- Check Firestore - verify `fcmTokens` array has multiple entries
- Check Cloud Function logs - ensure it's sending to all tokens
- Verify both devices have notification permissions enabled

**Tokens not being added?**

- Check app logs for FCM token retrieval errors
- Verify Firebase is properly initialized
- Check internet connectivity on device

**Old tokens not being cleaned up?**

- `cleanupInactiveTokens()` runs on app initialization
- Manually call if needed: `NotificationService().cleanupInactiveTokens()`

## Performance Considerations

- **Token Array Size**: Limited to ~100 devices per user (reasonable limit)
- **Firestore Reads**: One read per notification send (to get tokens)
- **FCM Quota**: 1 million free messages per month with Firebase
- **Cleanup Frequency**: Runs on each app initialization (minimal impact)

---

**Last Updated**: October 26, 2025
**Version**: 2.0.0
