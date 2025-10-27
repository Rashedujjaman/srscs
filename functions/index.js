const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ============================================================================
// NOTIFICATION FUNCTION 1: Complaint Status Change
// ============================================================================

/**
 * Send push notification when complaint status changes
 * Triggers: When a complaint document is updated
 * Sends to: ALL DEVICES of the user who submitted the complaint (UPDATED FOR MULTI-DEVICE)
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
      // Try to find user in all collections (citizens, contractors, admins)
      let userDoc = null;
      let userRef = null;

      const collections = ["citizens", "contractors", "admins"];
      for (const collection of collections) {
        const doc = await admin
          .firestore()
          .collection(collection)
          .doc(userId)
          .get();
        if (doc.exists) {
          userDoc = doc;
          userRef = doc.ref;
          console.log(`User found in ${collection} collection`);
          break;
        }
      }

      if (!userDoc || !userDoc.exists) {
        console.log(`User ${userId} not found in any collection`);
        return null;
      }

      const userData = userDoc.data();
      const preferences = userData.notificationPreferences || {};

      // Check if user has enabled complaint update notifications
      if (preferences.complaintUpdates === false) {
        console.log(
          `User ${userId} has disabled complaint update notifications`
        );
        return null;
      }

      // Get all FCM tokens from the fcmTokens array (MULTI-DEVICE SUPPORT)
      const fcmTokens = userData.fcmTokens || [];
      const tokens = fcmTokens.filter((t) => t && t.token).map((t) => t.token);

      if (tokens.length === 0) {
        console.log(`No FCM tokens found for user ${userId}`);
        return null;
      }

      console.log(`Found ${tokens.length} device(s) for user ${userId}`);

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

      // Send notification to ALL devices
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
      };

      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });

      console.log(
        `✅ Notification sent to ${response.successCount} device(s), ` +
          `failed: ${response.failureCount}`
      );

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const invalidTokenIndices = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`Failed to send to device ${idx}:`, resp.error);
            invalidTokenIndices.push(idx);
          }
        });

        if (invalidTokenIndices.length > 0) {
          const validTokens = fcmTokens.filter(
            (_, idx) => !invalidTokenIndices.includes(idx)
          );
          await userRef.update({ fcmTokens: validTokens });
          console.log(`Removed ${invalidTokenIndices.length} invalid token(s)`);
        }
      }

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
// NOTIFICATION FUNCTION 3: New Complaint Created (Notify Admin)
// ============================================================================

/**
 * Send push notification when a new complaint is submitted
 * Triggers: When a new complaint document is created
 * Sends to: ALL ADMINS (so they can review and assign)
 */
exports.onComplaintCreated = functions.firestore
  .document("complaints/{complaintId}")
  .onCreate(async (snapshot, context) => {
    const complaintData = snapshot.data();
    const complaintId = context.params.complaintId;

    console.log(`New complaint created: ${complaintId}`);

    try {
      // Get all admin users with FCM tokens
      const adminsSnapshot = await admin.firestore().collection("admins").get();

      if (adminsSnapshot.empty) {
        console.log("No admin users found");
        return null;
      }

      // Collect all admin tokens (supporting multi-device)
      const adminTokens = [];
      adminsSnapshot.docs.forEach((doc) => {
        const adminData = doc.data();
        const preferences = adminData.notificationPreferences || {};

        // Check if admin has enabled complaint notifications (default: true)
        if (preferences.complaintUpdates !== false) {
          const fcmTokens = adminData.fcmTokens || [];
          fcmTokens.forEach((tokenObj) => {
            if (tokenObj && tokenObj.token) {
              adminTokens.push(tokenObj.token);
            }
          });
        }
      });

      if (adminTokens.length === 0) {
        console.log("No admin FCM tokens found");
        return null;
      }

      console.log(
        `Sending notification to ${adminTokens.length} admin device(s)`
      );

      // Prepare notification content
      const complaintType = complaintData.type || "complaint";
      const area = complaintData.area || "Unknown area";
      const priority = complaintData.priority || "normal";

      const message = {
        notification: {
          title: "📋 New Complaint Received",
          body: `${complaintType} complaint at ${area}`,
        },
        data: {
          type: "new_complaint",
          complaintId: complaintId,
          complaintType: complaintType,
          priority: priority,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: priority === "high" ? "high" : "normal",
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
      };

      const response = await admin.messaging().sendEachForMulticast({
        tokens: adminTokens,
        ...message,
      });

      console.log(
        `✅ New complaint notification sent to ${response.successCount} admin device(s), ` +
          `failed: ${response.failureCount}`
      );

      return response;
    } catch (error) {
      console.error("❌ Error sending new complaint notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 4: Complaint Assigned to Contractor
// ============================================================================

/**
 * Send push notification when complaint is assigned to contractor
 * Triggers: When assignedTo field is updated
 * Sends to: Specific contractor
 */
exports.onComplaintAssigned = functions.firestore
  .document("complaints/{complaintId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const complaintId = context.params.complaintId;

    // Check if assignedTo field changed
    if (beforeData.assignedTo === afterData.assignedTo) {
      console.log("assignedTo unchanged, skipping notification");
      return null;
    }

    const contractorId = afterData.assignedTo;

    if (!contractorId) {
      console.log("No contractor assigned, skipping notification");
      return null;
    }

    console.log(
      `Complaint ${complaintId} assigned to contractor: ${contractorId}`
    );

    try {
      // Get contractor document
      const contractorDoc = await admin
        .firestore()
        .collection("contractors")
        .doc(contractorId)
        .get();

      if (!contractorDoc.exists) {
        console.log(`Contractor ${contractorId} not found`);
        return null;
      }

      const contractorData = contractorDoc.data();
      const preferences = contractorData.notificationPreferences || {};

      // Check if contractor has enabled complaint notifications
      if (preferences.complaintUpdates === false) {
        console.log(
          `Contractor ${contractorId} has disabled complaint notifications`
        );
        return null;
      }

      // Get all FCM tokens for this contractor (multi-device support)
      const fcmTokens = contractorData.fcmTokens || [];
      const tokens = fcmTokens.filter((t) => t && t.token).map((t) => t.token);

      if (tokens.length === 0) {
        console.log(`No FCM tokens found for contractor ${contractorId}`);
        return null;
      }

      console.log(
        `Found ${tokens.length} device(s) for contractor ${contractorId}`
      );

      // Prepare notification content
      const complaintType = afterData.type || "complaint";
      const area = afterData.area || "Unknown area";
      const priority = afterData.priority || "normal";

      const message = {
        notification: {
          title: "🔧 New Task Assigned",
          body: `${complaintType} at ${area}`,
        },
        data: {
          type: "task_assigned",
          complaintId: complaintId,
          complaintType: complaintType,
          priority: priority,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: priority === "high" ? "high" : "normal",
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
      };

      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...message,
      });

      console.log(
        `✅ Task assignment notification sent to ${response.successCount} device(s), ` +
          `failed: ${response.failureCount}`
      );

      return response;
    } catch (error) {
      console.error("❌ Error sending task assignment notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 5: Chat Message Notifications (Bidirectional)
// ============================================================================

/**
 * Send push notification for chat messages
 * Handles both directions:
 * 1. Admin → Citizen/Contractor: Notify the user
 * 2. Citizen/Contractor → Admin: Notify all admins
 *
 * Triggers: When a new message is added to any chat
 * Sends to: Either the user (if from admin) OR all admins (if from user)
 */
exports.onChatMessage = functions.database
  .ref("chats/{userId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const userId = context.params.userId;
    const messageId = context.params.messageId;

    console.log(`📬 New chat message for user ${userId}:`, messageId);

    try {
      // ========================================================================
      // SCENARIO 1: Admin sent message → Notify Citizen/Contractor
      // ========================================================================
      if (messageData.isAdmin === true) {
        console.log("→ Admin sent message, notifying user");

        // Try to find user in citizens collection first, then contractors
        let userDoc = null;
        let userData = null;
        let userType = "";

        const citizenDoc = await admin
          .firestore()
          .collection("citizens")
          .doc(userId)
          .get();

        if (citizenDoc.exists) {
          userDoc = citizenDoc;
          userData = citizenDoc.data();
          userType = "citizen";
        } else {
          const contractorDoc = await admin
            .firestore()
            .collection("contractors")
            .doc(userId)
            .get();

          if (contractorDoc.exists) {
            userDoc = contractorDoc;
            userData = contractorDoc.data();
            userType = "contractor";
          }
        }

        if (!userDoc || !userData) {
          console.log(`❌ User ${userId} not found in citizens or contractors`);
          return null;
        }

        console.log(`✅ Found user in ${userType} collection`);

        // Check if user is currently viewing the chat (to prevent notification spam)
        const chatStatusRef = admin
          .database()
          .ref(`chats/${userId}/chatStatus`);
        const chatStatusSnapshot = await chatStatusRef.once("value");
        const chatStatus = chatStatusSnapshot.val();

        if (chatStatus && chatStatus.isViewing === true) {
          console.log(
            `⚠️ User ${userId} is currently viewing chat, skipping notification`
          );
          return null;
        }

        const preferences = userData.notificationPreferences || {};

        // Check if user has enabled chat message notifications
        if (preferences.chatMessages === false) {
          console.log(
            `⚠️ User ${userId} has disabled chat message notifications`
          );
          return null;
        }

        // Get all FCM tokens (multi-device support)
        const fcmTokens = userData.fcmTokens || [];
        const tokens = fcmTokens
          .filter((t) => t && t.token)
          .map((t) => t.token);

        if (tokens.length === 0) {
          console.log(`❌ No FCM tokens found for user ${userId}`);
          return null;
        }

        console.log(`📱 Found ${tokens.length} device(s) for user ${userId}`);

        // Prepare notification
        const message = {
          notification: {
            title: "💬 New Message from Admin",
            body:
              messageData.message.length > 100
                ? messageData.message.substring(0, 97) + "..."
                : messageData.message,
          },
          data: {
            type: "admin_chat_message",
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
        };

        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokens,
          ...message,
        });

        console.log(
          `✅ Admin message notification sent to ${response.successCount} device(s), ` +
            `failed: ${response.failureCount}`
        );

        return response;
      }

      // ========================================================================
      // SCENARIO 2: Citizen/Contractor sent message → Notify All Admins
      // ========================================================================
      else {
        console.log("→ User sent message, notifying all admins");

        // Try to find user in citizens first, then contractors
        let userName = "A user";
        let userType = "user";

        const citizenDoc = await admin
          .firestore()
          .collection("citizens")
          .doc(userId)
          .get();

        if (citizenDoc.exists) {
          userName = citizenDoc.data().name || "A citizen";
          userType = "citizen";
        } else {
          const contractorDoc = await admin
            .firestore()
            .collection("contractors")
            .doc(userId)
            .get();

          if (contractorDoc.exists) {
            userName = contractorDoc.data().name || "A contractor";
            userType = "contractor";
          }
        }

        console.log(`📝 Message from ${userType}: ${userName}`);

        // Check if any admin is currently viewing this chat
        const adminChatStatusRef = admin
          .database()
          .ref(`admin_chat_status/${userId}`);
        const adminChatStatusSnapshot = await adminChatStatusRef.once("value");
        const adminChatStatus = adminChatStatusSnapshot.val();

        if (adminChatStatus && adminChatStatus.isViewing === true) {
          console.log(
            `⚠️ Admin is currently viewing chat with ${userId}, skipping notification`
          );
          return null;
        }

        // Get all admin users
        const adminsSnapshot = await admin
          .firestore()
          .collection("admins")
          .get();

        if (adminsSnapshot.empty) {
          console.log("❌ No admin users found");
          return null;
        }

        // Collect all admin tokens
        const adminTokens = [];
        adminsSnapshot.docs.forEach((doc) => {
          const adminData = doc.data();
          const preferences = adminData.notificationPreferences || {};

          // Check if admin has enabled chat notifications (default: true)
          if (preferences.chatMessages !== false) {
            const fcmTokens = adminData.fcmTokens || [];
            fcmTokens.forEach((tokenObj) => {
              if (tokenObj && tokenObj.token) {
                adminTokens.push(tokenObj.token);
              }
            });
          }
        });

        if (adminTokens.length === 0) {
          console.log("❌ No admin FCM tokens found");
          return null;
        }

        console.log(
          `📱 Sending notification to ${adminTokens.length} admin device(s)`
        );

        // Prepare notification
        const message = {
          notification: {
            title: `💬 New Message from ${userName}`,
            body:
              messageData.message.length > 100
                ? messageData.message.substring(0, 97) + "..."
                : messageData.message,
          },
          data: {
            type: "user_chat_message",
            userId: userId,
            messageId: messageId,
            userType: userType,
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
        };

        const response = await admin.messaging().sendEachForMulticast({
          tokens: adminTokens,
          ...message,
        });

        console.log(
          `✅ User message notification sent to ${response.successCount} admin device(s), ` +
            `failed: ${response.failureCount}`
        );

        return response;
      }
    } catch (error) {
      console.error("❌ Error sending chat notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 6: Contractor Chat Message (Notify Admin)
// ============================================================================

/**
 * Send push notification for contractor chat messages (bidirectional)
 * Handles both directions:
 * 1. Admin → Contractor: Notify the contractor
 * 2. Contractor → Admin: Notify all admins
 *
 * Triggers: When a message is added to contractor chat
 * Sends to: Either the contractor (if from admin) OR all admins (if from contractor)
 */
exports.onContractorChatMessage = functions.database
  .ref("contractor_chats/{contractorId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const contractorId = context.params.contractorId;
    const messageId = context.params.messageId;

    console.log(
      `📬 New contractor chat message for ${contractorId}:`,
      messageId
    );

    try {
      // ========================================================================
      // SCENARIO 1: Admin sent message → Notify Contractor
      // ========================================================================
      if (messageData.isAdmin === true) {
        console.log("→ Admin sent message, notifying contractor");

        // Check if contractor is currently viewing the chat
        const chatStatusRef = admin
          .database()
          .ref(`contractor_chats/${contractorId}/chatStatus`);
        const chatStatusSnapshot = await chatStatusRef.once("value");
        const chatStatus = chatStatusSnapshot.val();

        if (chatStatus && chatStatus.isViewing === true) {
          console.log(
            `⚠️ Contractor ${contractorId} is currently viewing chat, skipping notification`
          );
          return null;
        }

        // Get contractor document
        const contractorDoc = await admin
          .firestore()
          .collection("contractors")
          .doc(contractorId)
          .get();

        if (!contractorDoc.exists) {
          console.log(`❌ Contractor ${contractorId} not found`);
          return null;
        }

        const contractorData = contractorDoc.data();
        const preferences = contractorData.notificationPreferences || {};

        // Check if contractor has enabled chat message notifications
        if (preferences.chatMessages === false) {
          console.log(
            `⚠️ Contractor ${contractorId} has disabled chat message notifications`
          );
          return null;
        }

        // Get all FCM tokens (multi-device support)
        const fcmTokens = contractorData.fcmTokens || [];
        const tokens = fcmTokens
          .filter((t) => t && t.token)
          .map((t) => t.token);

        if (tokens.length === 0) {
          console.log(`❌ No FCM tokens found for contractor ${contractorId}`);
          return null;
        }

        console.log(
          `📱 Found ${tokens.length} device(s) for contractor ${contractorId}`
        );

        // Prepare notification
        const message = {
          notification: {
            title: "💬 New Message from Admin",
            body:
              messageData.message.length > 100
                ? messageData.message.substring(0, 97) + "..."
                : messageData.message,
          },
          data: {
            type: "admin_contractor_chat_message",
            contractorId: contractorId,
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
        };

        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokens,
          ...message,
        });

        console.log(
          `✅ Admin message notification sent to contractor: ${response.successCount} device(s), ` +
            `failed: ${response.failureCount}`
        );

        return response;
      }

      // ========================================================================
      // SCENARIO 2: Contractor sent message → Notify All Admins
      // ========================================================================
      else {
        console.log("→ Contractor sent message, notifying all admins");

        // Check if any admin is currently viewing this contractor chat
        const adminChatStatusRef = admin
          .database()
          .ref(`admin_chat_status/${contractorId}`);
        const adminChatStatusSnapshot = await adminChatStatusRef.once("value");
        const adminChatStatus = adminChatStatusSnapshot.val();

        if (adminChatStatus && adminChatStatus.isViewing === true) {
          console.log(
            `⚠️ Admin is currently viewing chat with contractor ${contractorId}, skipping notification`
          );
          return null;
        }

        // Get contractor name
        const contractorDoc = await admin
          .firestore()
          .collection("contractors")
          .doc(contractorId)
          .get();

        const contractorName = contractorDoc.exists
          ? contractorDoc.data().name || "A contractor"
          : "A contractor";

        console.log(`📝 Message from contractor: ${contractorName}`);

        // Get all admin users
        const adminsSnapshot = await admin
          .firestore()
          .collection("admins")
          .get();

        if (adminsSnapshot.empty) {
          console.log("❌ No admin users found");
          return null;
        }

        // Collect all admin tokens
        const adminTokens = [];
        adminsSnapshot.docs.forEach((doc) => {
          const adminData = doc.data();
          const preferences = adminData.notificationPreferences || {};

          // Check if admin has enabled chat notifications (default: true)
          if (preferences.chatMessages !== false) {
            const fcmTokens = adminData.fcmTokens || [];
            fcmTokens.forEach((tokenObj) => {
              if (tokenObj && tokenObj.token) {
                adminTokens.push(tokenObj.token);
              }
            });
          }
        });

        if (adminTokens.length === 0) {
          console.log("❌ No admin FCM tokens found");
          return null;
        }

        console.log(
          `📱 Sending notification to ${adminTokens.length} admin device(s)`
        );

        // Prepare notification
        const message = {
          notification: {
            title: `💬 New Message from ${contractorName}`,
            body:
              messageData.message.length > 100
                ? messageData.message.substring(0, 97) + "..."
                : messageData.message,
          },
          data: {
            type: "contractor_chat_message",
            contractorId: contractorId,
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
        };

        const response = await admin.messaging().sendEachForMulticast({
          tokens: adminTokens,
          ...message,
        });

        console.log(
          `✅ Contractor chat notification sent to ${response.successCount} admin device(s), ` +
            `failed: ${response.failureCount}`
        );

        return response;
      }
    } catch (error) {
      console.error("❌ Error sending contractor chat notification:", error);
      return null;
    }
  });

// ============================================================================
// NOTIFICATION FUNCTION 7: High Priority News
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
