# Firebase Cloud Functions for SRSCS

This directory contains Firebase Cloud Functions for sending push notifications.

## Functions Implemented

### 1. `onComplaintStatusChange`

- **Trigger**: When a complaint document is updated
- **Sends to**: Individual user who submitted the complaint
- **Conditions**: Only when status changes
- **Notification Types**:
  - Under Review: "Your complaint is now being reviewed"
  - In Progress: "Work has started on your complaint"
  - Resolved: "Your complaint has been successfully resolved"
  - Rejected: "Your complaint was rejected"

### 2. `onUrgentNoticeCreated`

- **Trigger**: When a notice with type 'emergency' or 'warning' is created
- **Sends to**: All users (topic: 'urgent_notices')
- **Notification Types**:
  - Emergency: "🚨 EMERGENCY ALERT"
  - Warning: "⚠️ WARNING"

### 3. `onAdminChatReply`

- **Trigger**: When admin sends a message in chat
- **Sends to**: Individual user
- **Content**: Preview of admin's message

### 4. `onHighPriorityNews`

- **Trigger**: When news with priority 5 is created
- **Sends to**: Users who have enabled news alerts
- **Content**: News title and link

### 5. `cleanupInvalidTokens`

- **Schedule**: Daily at 2:00 AM (Asia/Dhaka)
- **Purpose**: Remove invalid FCM tokens from Firestore

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Initialize Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

Choose:

- Existing project: Select your SRSCS project
- Language: JavaScript
- ESLint: No
- Install dependencies: Yes

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onComplaintStatusChange
```

### 4. Test Functions Locally

```bash
# Start emulator
firebase emulators:start --only functions

# View logs
firebase functions:log
```

## Environment Variables

No environment variables needed. The functions use Firebase Admin SDK which automatically inherits project credentials.

## Monitoring

### View Logs

```bash
firebase functions:log
```

### Firebase Console

1. Go to Firebase Console
2. Navigate to Functions section
3. Click on a function to see logs, metrics, and usage

## User Notification Preferences

Users can control which notifications they receive:

```javascript
{
  notificationPreferences: {
    complaintUpdates: true,    // Complaint status changes
    urgentNotices: true,        // Emergency/Warning notices
    chatMessages: true,         // Admin chat replies
    newsAlerts: false           // High priority news (opt-in)
  }
}
```

These preferences are stored in Firestore at `/citizens/{userId}/notificationPreferences`.

## Testing

### Test Complaint Status Change

1. Update a complaint status in Firestore
2. Check user's device for notification

### Test Urgent Notice

1. Add a notice with type 'emergency' or 'warning'
2. All subscribed users should receive notification

### Test Chat Reply

1. Send a message as admin in Firebase Realtime Database
2. User should receive notification

## Troubleshooting

### Function not triggering

- Check Firebase Console → Functions → Logs
- Verify Firestore/Realtime Database triggers are correct
- Ensure user has valid FCM token

### Notification not received

- Check user's notification preferences
- Verify FCM token is valid
- Check device notification settings
- View function logs for errors

### Token errors

- Invalid tokens are automatically cleaned up daily
- Users will get new tokens on next app launch

## Cost Optimization

- Functions run only when triggered (pay-per-use)
- Invalid tokens are cleaned up daily
- Multicast used for sending to multiple users
- Topic messaging used for broadcast notifications

## Security

- Functions run with Firebase Admin SDK privileges
- User preferences checked before sending
- Tokens stored securely in Firestore
- No sensitive data in notification payload

---

**Need Help?** Check [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
