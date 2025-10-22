const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ============================================================================
// NOTIFICATION FUNCTION 1: Complaint Status Change
// ============================================================================

/**
 * Send push notification when complaint status changes
 * Triggers: When a complaint document is updated
 * Sends to: Individual user who submitted the complaint
 */
exports.onComplaintStatusChange = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const complaintId = context.params.complaintId;

    // Check if status actually changed
    if (beforeData.status === afterData.status) {
      console.log("Status unchanged, skipping notification");
      return null;
    }

    const userId = afterData.userId;
    const newStatus = afterData.status;
    const complaintType = afterData.type || "complaint";

    console.log(
      `Complaint ${complaintId} status changed: ${beforeData.status} → ${newStatus}`
    );

    try {
      // Get user document to check preferences and FCM token
      const userDoc = await admin
        .firestore()
        .collection("citizens")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      const preferences = userData.notificationPreferences || {};

      // Check if user has enabled complaint update notifications
      if (preferences.complaintUpdates === false) {
        console.log(
          `User ${userId} has disabled complaint update notifications`
        );
        return null;
      }

      if (!fcmToken) {
        console.log(`No FCM token found for user ${userId}`);
        return null;
      }

      // Prepare notification content based on status
      let title, body, priority;

      switch (newStatus) {
        case "underReview":
          title = "👀 Complaint Under Review";
          body = `Your ${complaintType} complaint is now being reviewed by authorities`;
          priority = "normal";
          break;
        case "inProgress":
          title = "🔧 Work in Progress";
          body = `Great news! Work has started on your ${complaintType} complaint`;
          priority = "high";
          break;
        case "resolved":
          title = "✅ Complaint Resolved";
          body = `Excellent! Your ${complaintType} complaint has been successfully resolved`;
          priority = "high";
          break;
        case "rejected":
          title = "❌ Complaint Rejected";
          body = `Your ${complaintType} complaint was rejected. Tap to view details`;
          priority = "high";
          break;
        default:
          title = "📋 Complaint Update";
          body = `Your complaint status has been updated to ${newStatus}`;
          priority = "normal";
      }

      // Send notification
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "complaint_status",
          complaintId: complaintId,
          status: newStatus,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: priority === "high" ? "high" : "normal",
          notification: {
            channelId: "srscs_high_importance",
            sound: "default",
            priority: priority === "high" ? "high" : "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log(
        `✅ Notification sent successfully to user ${userId}:`,
        response
      );

      return response;
    } catch (error) {
      console.error("❌ Error sending complaint status notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 2: Urgent Notice Created
// ============================================================================

/**
 * Send push notification when urgent notice is created
 * Triggers: When a notice with type 'emergency' or 'warning' is created
 * Sends to: All users (topic: 'urgent_notices')
 */
exports.onUrgentNoticeCreated = functions.firestore
  .document("notices/{noticeId}")
  .onCreate(async (snapshot, context) => {
    const noticeData = snapshot.data();
    const noticeId = context.params.noticeId;
    const noticeType = noticeData.type;

    console.log(`New notice created: ${noticeId}, type: ${noticeType}`);

    // Only send for emergency or warning notices
    if (noticeType !== "emergency" && noticeType !== "warning") {
      console.log("Notice is not urgent, skipping notification");
      return null;
    }

    try {
      let title, emoji, priority;

      switch (noticeType) {
        case "emergency":
          emoji = "🚨";
          title = "EMERGENCY ALERT";
          priority = "max";
          break;
        case "warning":
          emoji = "⚠️";
          title = "WARNING";
          priority = "high";
          break;
        default:
          emoji = "📢";
          title = "NOTICE";
          priority = "normal";
      }

      // Get all users with FCM tokens who have urgent notices enabled
      const usersSnapshot = await admin
        .firestore()
        .collection("citizens")
        .where("fcmToken", "!=", null)
        .get();

      if (usersSnapshot.empty) {
        console.log("No users with FCM tokens found");
        return null;
      }

      // Filter users based on preferences
      const tokens = [];
      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        const preferences = userData.notificationPreferences || {};

        // Check if user has enabled urgent notice notifications (default: true)
        if (preferences.urgentNotices !== false) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No users have enabled urgent notice notifications");
        return null;
      }

      console.log(`Sending notification to ${tokens.length} users`);

      // Send to topic instead of individual tokens (more efficient)
      const message = {
        notification: {
          title: `${emoji} ${title}`,
          body: noticeData.title,
        },
        data: {
          type: "urgent_notice",
          noticeId: noticeId,
          noticeType: noticeType,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: priority === "max" ? "high" : "high",
          notification: {
            channelId: "srscs_high_importance",
            sound: "default",
            priority: priority === "max" ? "max" : "high",
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              alert: {
                title: `${emoji} ${title}`,
                body: noticeData.title,
              },
            },
          },
        },
        topic: "urgent_notices",
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Urgent notice notification sent:`, response);

      return response;
    } catch (error) {
      console.error("❌ Error sending urgent notice notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 3: Admin Chat Reply
// ============================================================================
// NOTE: This function requires Firebase Realtime Database to be enabled
// To enable: Go to Firebase Console > Realtime Database > Create Database
// Then uncomment this function and redeploy

/**
 * Send push notification when admin replies in chat
 * Triggers: When a new message is added to user's chat (from admin)
 * Sends to: Individual user
 */
/*
exports.onAdminChatReply = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const userId = context.params.userId;
    const messageId = context.params.messageId;

    console.log(`New chat message for user ${userId}:`, messageId);

    // Only send notification if message is from admin
    if (!messageData.isAdmin) {
      console.log("Message is from user, not admin. Skipping notification");
      return null;
    }

    try {
      // Get user document
      const userDoc = await admin
        .firestore()
        .collection("citizens")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      const preferences = userData.notificationPreferences || {};

      // Check if user has enabled chat message notifications
      if (preferences.chatMessages === false) {
        console.log(`User ${userId} has disabled chat message notifications`);
        return null;
      }

      if (!fcmToken) {
        console.log(`No FCM token found for user ${userId}`);
        return null;
      }

      // Prepare notification
      const message = {
        notification: {
          title: "💬 Admin Reply",
          body:
            messageData.message.length > 100
              ? messageData.message.substring(0, 97) + "..."
              : messageData.message,
        },
        data: {
          type: "chat_message",
          userId: userId,
          messageId: messageId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "srscs_high_importance",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log(
        `✅ Chat reply notification sent to user ${userId}:`,
        response
      );

      return response;
    } catch (error) {
      console.error("❌ Error sending chat reply notification:", error);
      return null;
    }
  });
*/

// ============================================================================
// NOTIFICATION FUNCTION 4: High Priority News
// ============================================================================

/**
 * Send push notification for high priority news
 * Triggers: When news with priority 5 is created
 * Sends to: Users who have enabled news alerts
 */
exports.onHighPriorityNews = functions.firestore
  .document("news/{newsId}")
  .onCreate(async (snapshot, context) => {
    const newsData = snapshot.data();
    const newsId = context.params.newsId;
    const priority = newsData.priority || 1;

    console.log(`New news created: ${newsId}, priority: ${priority}`);

    // Only send for high priority news (priority 5)
    if (priority < 5) {
      console.log("News priority is not high enough, skipping notification");
      return null;
    }

    try {
      // Get users who have enabled news alerts
      const usersSnapshot = await admin
        .firestore()
        .collection("citizens")
        .where("fcmToken", "!=", null)
        .get();

      if (usersSnapshot.empty) {
        console.log("No users with FCM tokens found");
        return null;
      }

      // Filter users based on preferences
      const tokens = [];
      usersSnapshot.docs.forEach((doc) => {
        const userData = doc.data();
        const preferences = userData.notificationPreferences || {};

        // Check if user has enabled news alerts (default: false)
        if (preferences.newsAlerts === true) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No users have enabled news alert notifications");
        return null;
      }

      console.log(`Sending news notification to ${tokens.length} users`);

      // Send multicast message
      const message = {
        notification: {
          title: "📰 Important News",
          body: newsData.title,
        },
        data: {
          type: "news",
          newsId: newsId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "normal",
          notification: {
            channelId: "srscs_high_importance",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(
        `✅ News notification sent: ${response.successCount} successful, ${response.failureCount} failed`
      );

      return response;
    } catch (error) {
      console.error("❌ Error sending news notification:", error);
      return null;
    }
  });

// ============================================================================
// UTILITY FUNCTION: Clean up old FCM tokens
// ============================================================================

/**
 * Scheduled function to clean up invalid FCM tokens
 * Runs: Daily at 2:00 AM
 */
exports.cleanupInvalidTokens = functions.pubsub
  .schedule("0 2 * * *") // Daily at 2:00 AM
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    console.log("🧹 Starting FCM token cleanup...");

    try {
      const usersSnapshot = await admin
        .firestore()
        .collection("citizens")
        .where("fcmToken", "!=", null)
        .get();

      let cleanedCount = 0;

      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const token = userData.fcmToken;

        // Check if token is still valid by sending a dry-run message
        try {
          await admin.messaging().send(
            {
              token: token,
              data: { test: "true" },
            },
            true // dry run
          );
        } catch (error) {
          // Token is invalid, remove it
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            await doc.ref.update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
            cleanedCount++;
            console.log(`Removed invalid token for user: ${doc.id}`);
          }
        }
      }

      console.log(
        `✅ Token cleanup complete. Removed ${cleanedCount} invalid tokens`
      );
      return null;
    } catch (error) {
      console.error("❌ Error during token cleanup:", error);
      return null;
    }
  });
