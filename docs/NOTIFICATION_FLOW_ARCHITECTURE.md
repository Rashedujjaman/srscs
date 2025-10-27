# Notification Flow Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SRSCS Notification System                       │
│                     Role-Based Navigation Architecture                  │
└─────────────────────────────────────────────────────────────────────────┘

                              Cloud Functions
                                   (Node.js)
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
           ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
           │   Firestore    │  │   Realtime DB  │  │   FCM Service  │
           │   Triggers     │  │   Triggers     │  │   (Push)       │
           └────────────────┘  └────────────────┘  └────────────────┘
                    │                 │                 │
                    └─────────────────┼─────────────────┘
                                      │
                         FCM Push Notification
                              (with data payload)
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
           ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
           │     CITIZEN    │  │   CONTRACTOR   │  │     ADMIN      │
           │    DEVICES     │  │    DEVICES     │  │    DEVICES     │
           └────────────────┘  └────────────────┘  └────────────────┘
                    │                 │                 │
                    │   Notification Service (Flutter)  │
                    │   notification_service.dart       │
                    │                 │                 │
                    └─────────────────┼─────────────────┘
                                      │
                          Role Detection & Routing
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
           ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
           │ Citizen Routes │  │Contractor Routes│  │  Admin Routes  │
           │ /dashboard     │  │/contractor/*    │  │  /admin/*      │
           │ /chat          │  │/contractor/chat │  │  /admin/chat   │
           │ /track-*       │  │/contractor/tasks│  │/admin/complaints│
           └────────────────┘  └────────────────┘  └────────────────┘
```

## Detailed Chat Notification Flow

### Scenario 1: Citizen → Admin Chat Message

```
┌─────────────┐                                              ┌─────────────┐
│   CITIZEN   │                                              │    ADMIN    │
│   Device    │                                              │   Device    │
└─────────────┘                                              └─────────────┘
      │                                                              │
      │ 1. Send Message                                             │
      │────────────────────▶                                        │
      │                    │                                        │
      │              ┌─────▼─────┐                                 │
      │              │ Realtime  │                                 │
      │              │ Database  │                                 │
      │              │/chats/{id}│                                 │
      │              └─────┬─────┘                                 │
      │                    │                                        │
      │              ┌─────▼──────────────────┐                    │
      │              │ Cloud Function         │                    │
      │              │ onChatMessage          │                    │
      │              │                        │                    │
      │              │ Detects: isAdmin=false │                    │
      │              │ Type: user_chat_message│                    │
      │              │ Data: {                │                    │
      │              │   userId: citizen_id   │                    │
      │              │   userType: 'citizen'  │                    │
      │              │ }                      │                    │
      │              └─────┬──────────────────┘                    │
      │                    │                                        │
      │                    │ 2. Send FCM Notification              │
      │                    │───────────────────────────────────────▶│
      │                    │                                        │
      │                    │                             ┌──────────▼─────────┐
      │                    │                             │ Notification Service│
      │                    │                             │ _handleNavigation() │
      │                    │                             │                     │
      │                    │                             │ Role: admin         │
      │                    │                             │ Type: user_chat_msg │
      │                    │                             │                     │
      │                    │                             │ Navigate to:        │
      │                    │                             │ /admin/chat/detail  │
      │                    │                             │ args: {             │
      │                    │                             │   userId: citizen_id│
      │                    │                             │   userType: citizen │
      │                    │                             │ }                   │
      │                    │                             └──────────┬─────────┘
      │                    │                                        │
      │                    │                             3. Admin sees specific
      │                    │                                citizen chat screen
      │                    │                                        │
```

### Scenario 2: Admin → Citizen Chat Message

```
┌─────────────┐                                              ┌─────────────┐
│    ADMIN    │                                              │   CITIZEN   │
│   Device    │                                              │   Device    │
└─────────────┘                                              └─────────────┘
      │                                                              │
      │ 1. Send Reply                                               │
      │────────────────────▶                                        │
      │                    │                                        │
      │              ┌─────▼─────┐                                 │
      │              │ Realtime  │                                 │
      │              │ Database  │                                 │
      │              │/chats/{id}│                                 │
      │              └─────┬─────┘                                 │
      │                    │                                        │
      │              ┌─────▼──────────────────┐                    │
      │              │ Cloud Function         │                    │
      │              │ onChatMessage          │                    │
      │              │                        │                    │
      │              │ Detects: isAdmin=true  │                    │
      │              │ Type: admin_chat_message│                   │
      │              │ Data: {                │                    │
      │              │   userId: citizen_id   │                    │
      │              │   messageId: msg_id    │                    │
      │              │ }                      │                    │
      │              └─────┬──────────────────┘                    │
      │                    │                                        │
      │                    │ 2. Send FCM Notification              │
      │                    │───────────────────────────────────────▶│
      │                    │                                        │
      │                    │                             ┌──────────▼─────────┐
      │                    │                             │ Notification Service│
      │                    │                             │ _handleNavigation() │
      │                    │                             │                     │
      │                    │                             │ Role: citizen       │
      │                    │                             │ Type: admin_chat_msg│
      │                    │                             │                     │
      │                    │                             │ Navigate to:        │
      │                    │                             │ /chat               │
      │                    │                             └──────────┬─────────┘
      │                    │                                        │
      │                    │                             3. Citizen sees chat
      │                    │                                with admin screen
      │                    │                                        │
```

## Complaint Notification Flow

### New Complaint Creation (Citizen → Admin)

```
┌─────────────┐                                              ┌─────────────┐
│   CITIZEN   │                                              │    ADMIN    │
│             │                                              │             │
└─────────────┘                                              └─────────────┘
      │                                                              │
      │ 1. Submit Complaint                                         │
      │────────────────────▶                                        │
      │                    │                                        │
      │              ┌─────▼─────┐                                 │
      │              │ Firestore │                                 │
      │              │/complaints│                                 │
      │              └─────┬─────┘                                 │
      │                    │                                        │
      │              ┌─────▼──────────────────┐                    │
      │              │ Cloud Function         │                    │
      │              │ onComplaintCreated     │                    │
      │              │                        │                    │
      │              │ Type: new_complaint    │                    │
      │              │ Data: {                │                    │
      │              │   complaintId: id      │                    │
      │              │   complaintType: type  │                    │
      │              │   priority: high       │                    │
      │              │ }                      │                    │
      │              └─────┬──────────────────┘                    │
      │                    │                                        │
      │                    │ 2. Notify ALL Admins                  │
      │                    │───────────────────────────────────────▶│
      │                    │                                        │
      │                    │                             ┌──────────▼─────────┐
      │                    │                             │ Notification Service│
      │                    │                             │                     │
      │                    │                             │ Role: admin         │
      │                    │                             │ Type: new_complaint │
      │                    │                             │                     │
      │                    │                             │ Navigate to:        │
      │                    │                             │ /admin/complaints   │
      │                    │                             └──────────┬─────────┘
      │                    │                                        │
      │                    │                             3. Admin reviews new
      │                    │                                complaint list
      │                    │                                        │
```

### Status Update (System → Citizen)

```
┌─────────────┐                                              ┌─────────────┐
│    ADMIN    │                                              │   CITIZEN   │
│             │                                              │             │
└─────────────┘                                              └─────────────┘
      │                                                              │
      │ 1. Update Status                                            │
      │────────────────────▶                                        │
      │                    │                                        │
      │              ┌─────▼─────┐                                 │
      │              │ Firestore │                                 │
      │              │/complaints│                                 │
      │              │{id}/status│                                 │
      │              └─────┬─────┘                                 │
      │                    │                                        │
      │              ┌─────▼──────────────────┐                    │
      │              │ Cloud Function         │                    │
      │              │onComplaintStatusChange │                    │
      │              │                        │                    │
      │              │ Type: complaint_status │                    │
      │              │ Data: {                │                    │
      │              │   complaintId: id      │                    │
      │              │   status: 'inProgress' │                    │
      │              │ }                      │                    │
      │              └─────┬──────────────────┘                    │
      │                    │                                        │
      │                    │ 2. Notify Complaint Owner             │
      │                    │───────────────────────────────────────▶│
      │                    │                                        │
      │                    │                             ┌──────────▼─────────┐
      │                    │                             │ Notification Service│
      │                    │                             │                     │
      │                    │                             │ Role: citizen       │
      │                    │                             │ Type: complaint_sts │
      │                    │                             │                     │
      │                    │                             │ Navigate to:        │
      │                    │                             │ /track-complaints   │
      │                    │                             └──────────┬─────────┘
      │                    │                                        │
      │                    │                             3. Citizen views
      │                    │                                complaint tracking
      │                    │                                        │
```

## Navigation Decision Tree

```
                    Notification Received
                            │
                            ▼
                   ┌────────────────┐
                   │ Get User Role  │
                   │ from AuthService│
                   └────────┬───────┘
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
          ┌─────────┐ ┌──────────┐ ┌─────────┐
          │ CITIZEN │ │CONTRACTOR│ │  ADMIN  │
          └────┬────┘ └────┬─────┘ └────┬────┘
               │           │            │
               │           │            │
      ┌────────┼───────┐   │    ┌───────┼────────┐
      ▼        ▼       ▼   ▼    ▼       ▼        ▼
 complaint  chat   notice task chat complaint  chat
  status    msg           assg  msg   new      mgmt
     │       │      │      │    │      │        │
     ▼       ▼      ▼      ▼    ▼      ▼        ▼
  /track-  /chat  /dash  /cont /cont /admin  /admin
  compl          board  /task  /chat /compl  /chat
                        -detail       aints   /detail
```

## Multi-Device Support

```
┌──────────────────────────────────────────────────────────────────┐
│                     Multi-Device Architecture                    │
└──────────────────────────────────────────────────────────────────┘

User Account (Firestore)
└─ fcmTokens: [
     {
       token: "fcm_token_1",
       platform: "android",
       lastActive: Timestamp,
       addedAt: Timestamp
     },
     {
       token: "fcm_token_2",
       platform: "ios",
       lastActive: Timestamp,
       addedAt: Timestamp
     }
   ]

                    ▼

      Cloud Function sends to ALL tokens
        (using sendEachForMulticast)

                    ▼

      ┌──────────────┬──────────────┐
      │              │              │
      ▼              ▼              ▼
  Device 1       Device 2       Device 3
  (Android)      (iOS)          (Web)
      │              │              │
      └──────────────┴──────────────┘
                    │
         Same navigation logic
         applied on each device
```

## Payload Structure

### Standard Notification Payload

```json
{
  "notification": {
    "title": "Notification Title",
    "body": "Notification Body"
  },
  "data": {
    "type": "notification_type",
    "id": "relevant_id",
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    // Additional context-specific fields:
    "userId": "user_id",
    "userType": "citizen|contractor",
    "complaintId": "complaint_id",
    "contractorId": "contractor_id",
    "messageId": "message_id",
    "priority": "high|normal"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channelId": "srscs_high_importance",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

## Error Handling Flow

```
Notification Received
        │
        ▼
    Get User ID
        │
        ├─ No User? ──▶ Log Error & Exit
        │
        ▼
    Get User Role
        │
        ├─ No Role? ──▶ Default to Citizen
        │
        ▼
  Extract Notification Type
        │
        ├─ Unknown Type? ──▶ Navigate to Dashboard
        │
        ▼
    Role-Based Routing
        │
        ├─ Invalid Route? ──▶ Navigate to Dashboard
        │
        ▼
    Navigate Successfully
```

---

**Architecture Version:** 2.0  
**Last Updated:** October 27, 2025  
**Supports:** Citizens, Contractors, Admins
