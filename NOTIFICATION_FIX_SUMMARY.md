# 🔔 Multi-Device Notification Fix - Summary

## Problem

Users were only receiving notifications on the **last device** they logged in with. When logging in on a new device, the old device stopped receiving notifications.

## Root Cause

The FCM token was stored as a **single field**, which got overwritten each time the user logged in on a different device.

## Solution

Changed the token storage from a single value to an **array of tokens**, allowing multiple devices per user account.

---

## ✅ Changes Made

### 1. **Client-Side (Flutter App)**

#### File: `lib/services/notification_service.dart`

**Updated Methods:**

- ✅ `_saveFCMTokenToFirestore()` - Now stores tokens in an array
- ✅ `deleteToken()` - Removes only current device token on logout
- ✅ `cleanupInactiveTokens()` - Removes tokens inactive for 30+ days
- ✅ `initialize()` - Calls cleanup on app start

**New Data Structure:**

```dart
{
  "fcmTokens": [
    {
      "token": "device-1-token-here",
      "platform": "android",
      "lastActive": Timestamp,
      "addedAt": Timestamp
    },
    {
      "token": "device-2-token-here",
      "platform": "ios",
      "lastActive": Timestamp,
      "addedAt": Timestamp
    }
  ],
  "fcmToken": "device-2-token-here",  // Latest (backward compatibility)
  "fcmTokenUpdatedAt": Timestamp
}
```

### 2. **Server-Side (Firebase Cloud Functions)**

#### File: `functions/index.js`

**Updated Function:**

- ✅ `onComplaintStatusChange` - Now sends to ALL devices
  - Searches across all collections (citizens, contractors, admins)
  - Uses `sendEachForMulticast()` to send to multiple tokens
  - Automatically removes invalid tokens
  - Logs success/failure count

---

## 🚀 Deployment Steps

### Step 1: Update Flutter App

The Flutter app has already been updated. You just need to **rebuild and redeploy**:

```bash
# Build for Android
flutter build apk --release

# Build for iOS (on Mac)
flutter build ios --release

# Or run in debug mode for testing
flutter run
```

### Step 2: Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies (if first time)
npm install

# Deploy the updated functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:onComplaintStatusChange
```

### Step 3: Verify Deployment

Check Firebase Console logs:

```
https://console.firebase.google.com/project/YOUR_PROJECT_ID/functions/logs
```

---

## 🧪 Testing Multi-Device Support

### Test Case 1: Two Devices, Same Account

1. **Login on Device 1** (Android phone)

   - Check Firestore: `fcmTokens` array should have 1 entry
   - Note the token value

2. **Login on Device 2** (Another Android/iOS device)

   - Check Firestore: `fcmTokens` array should now have 2 entries
   - Both tokens should be present

3. **Change Complaint Status** (as admin)

   - Both Device 1 and Device 2 should receive notification
   - Check Cloud Function logs: Should show "sent to 2 device(s)"

4. **Logout from Device 1**
   - Check Firestore: `fcmTokens` should have only 1 entry (Device 2)
   - Device 2 should still receive notifications

### Test Case 2: Invalid Token Cleanup

1. **Uninstall app from Device 1** (don't logout)

   - Token remains in Firestore

2. **Change complaint status**
   - Device 2 receives notification
   - Invalid token (Device 1) automatically removed
   - Check logs: Should show "Removed 1 invalid token(s)"

### Test Case 3: Inactive Token Cleanup

1. **Don't use Device 1 for 30+ days**

   - Token still in Firestore

2. **Login on Device 2**
   - `cleanupInactiveTokens()` runs automatically
   - Tokens older than 30 days are removed
   - Check logs: Should show "Cleaned up X inactive tokens"

---

## 📊 Monitoring & Debugging

### Check Firestore Data

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `citizens/{userId}` (or contractors/admins)
4. Look for `fcmTokens` array field

**Expected Structure:**

```json
{
  "email": "user@example.com",
  "fcmTokens": [
    {
      "token": "fMxT...",
      "platform": "android",
      "lastActive": "2025-10-26T10:30:00Z",
      "addedAt": "2025-10-20T08:15:00Z"
    }
  ]
}
```

### Check Cloud Function Logs

```bash
# View logs in terminal
firebase functions:log

# Or in Firebase Console
# https://console.firebase.google.com/project/YOUR_PROJECT/functions/logs
```

**Look for:**

- ✅ `Found X device(s) for user...`
- ✅ `Notification sent to X device(s), failed: X`
- ❌ `No FCM tokens found for user...`

### Common Issues

**Issue 1: Still only one device receiving**

- **Check:** Firestore `fcmTokens` array - does it have multiple entries?
- **Solution:** Ensure app is updated on both devices

**Issue 2: No notifications at all**

- **Check:** Cloud Function logs for errors
- **Check:** User's notification preferences in Firestore
- **Solution:** Verify `notificationPreferences.complaintUpdates` is not `false`

**Issue 3: Old tokens not cleaned up**

- **Check:** App initialization logs
- **Solution:** Call `NotificationService().cleanupInactiveTokens()` manually

---

## 🎯 Key Features

✅ **Multiple Devices** - Unlimited devices per account
✅ **Auto Cleanup** - Removes tokens inactive for 30+ days
✅ **Invalid Token Handling** - Automatically removes failed tokens
✅ **Platform Tracking** - Knows which devices are Android/iOS
✅ **Selective Logout** - Logout on one device doesn't affect others
✅ **Backward Compatible** - Works with old single-token setup

---

## 📱 User Experience

### Before Fix

```
Login on Phone → Get notifications ✅
Login on Tablet → Get notifications ✅
Phone stops getting notifications ❌
```

### After Fix

```
Login on Phone → Get notifications ✅
Login on Tablet → Get notifications ✅
Both devices get notifications ✅✅
```

---

## 💡 Tips

1. **Test thoroughly** before production deployment
2. **Monitor logs** for the first few days after deployment
3. **Set up alerts** for Cloud Function errors
4. **Consider rate limiting** if you have many users
5. **Document the change** for your team

---

## 🆘 Support

If you encounter issues:

1. Check Firestore structure matches the expected format
2. Verify Cloud Functions deployed successfully
3. Review Cloud Function logs for errors
4. Test with a fresh user account
5. Check Firebase Console quota limits

---

## 📝 Next Steps

After successful deployment:

- [ ] Test with 2+ devices
- [ ] Monitor Cloud Function logs
- [ ] Check notification delivery rates
- [ ] Update app documentation
- [ ] Inform users about multi-device support

---

**Last Updated**: October 26, 2025
**Status**: ✅ Ready for Deployment
