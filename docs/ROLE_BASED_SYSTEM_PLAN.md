# Role-Based System Implementation Plan

## 🎯 Overview

Transform SRSCS into a unified role-based application supporting three user types:

- **Citizens** - Submit and track complaints, chat with admin
- **Contractors** - View assigned complaints, update status, chat with admin
- **Admins** - Manage all complaints, assign to contractors, manage users

## 📋 Current vs New Architecture

### Before

```
Mobile App (Citizens) ────> Firebase
Web App (Admins/Contractors) ────> Firebase
```

### After

```
Single Mobile App
├── Citizen Role
├── Contractor Role
└── Admin Role (all access Firebase)
```

## 🔧 Required Changes

### 1. User Model Enhancement

**Current:**

```dart
class UserEntity {
  final String id;
  final String email;
  // citizen fields only
}
```

**New:**

```dart
class UserEntity {
  final String id;
  final String email;
  final UserRole role;
  final String? contractorArea;  // For contractors
  final DateTime createdAt;
  final String? createdBy;  // Admin ID who created contractor
}

enum UserRole {
  citizen,
  contractor,
  admin
}
```

### 2. Database Structure Changes

#### Firestore Collections

**citizens** (existing - enhanced)

```json
{
  "userId": {
    "email": "user@email.com",
    "fullName": "John Doe",
    "role": "citizen",
    "nid": "123456789",
    "phone": "...",
    "createdAt": timestamp
  }
}
```

**contractors** (new)

```json
{
  "contractorId": {
    "email": "contractor@email.com",
    "fullName": "Contractor Name",
    "role": "contractor",
    "phone": "...",
    "assignedArea": "Dhaka-North",
    "createdBy": "adminId",
    "createdAt": timestamp,
    "isActive": true
  }
}
```

**admins** (new)

```json
{
  "adminId": {
    "email": "admin@srscs.com",
    "fullName": "Admin Name",
    "role": "admin",
    "createdAt": timestamp
  }
}
```

**complaints** (enhanced)

```json
{
  "complaintId": {
    "userId": "citizenId",
    "title": "...",
    "description": "...",
    "location": "Dhaka-North",
    "status": "pending|assigned|in-progress|completed|rejected",
    "assignedTo": "contractorId",  // NEW
    "assignedBy": "adminId",       // NEW
    "assignedAt": timestamp,       // NEW
    "completedAt": timestamp,      // NEW
    "createdAt": timestamp
  }
}
```

**Realtime Database - chats** (enhanced)

```json
{
  "chats": {
    "citizen-admin-{citizenId}": {
      "participants": ["citizenId", "adminId"],
      "participantRoles": {
        "citizenId": "citizen",
        "adminId": "admin"
      },
      "lastMessage": "...",
      "messages": {}
    },
    "contractor-admin-{contractorId}": {
      "participants": ["contractorId", "adminId"],
      "participantRoles": {
        "contractorId": "contractor",
        "adminId": "admin"
      },
      "lastMessage": "...",
      "messages": {}
    }
  }
}
```

### 3. Authentication Flow Changes

#### Registration Flow

```
Citizen Registration (Public)
├── Email/Password signup
├── NID verification
└── Auto-assign role: "citizen"

Contractor Registration (Admin Only)
├── Admin creates account
├── Sets contractor area
└── Sends credentials to contractor

Admin Registration (System)
├── Created manually in Firebase
└── Initial seed data
```

#### Login Flow

```
Login
├── Check user role in Firestore
├── Route based on role:
│   ├── citizen -> Dashboard
│   ├── contractor -> ContractorDashboard
│   └── admin -> AdminDashboard
```

### 4. New Features to Implement

#### A. Contractor Management (Admin)

- Create contractor accounts
- Assign area to contractors
- View all contractors
- Activate/deactivate contractors

#### B. Complaint Assignment (Admin)

- View all complaints
- Filter by location/area
- Assign complaint to contractor in that area
- Reassign if needed
- Track assignment history

#### C. Contractor Dashboard

- View assigned complaints only
- Update complaint status
- Add progress notes
- Upload completion photos
- Chat with admin

#### D. Enhanced Admin Dashboard

- All complaints overview
- Pending assignments
- Contractor performance
- Area-wise statistics
- User management

### 5. UI Changes by Role

#### Citizen UI (Minimal Changes)

```
Bottom Navigation:
├── Dashboard
├── Submit Complaint
├── Track Complaints
├── Chat with Admin
└── Profile
```

#### Contractor UI (New)

```
Bottom Navigation:
├── Dashboard (assigned complaints)
├── Active Tasks
├── Completed Tasks
├── Chat with Admin
└── Profile
```

#### Admin UI (New)

```
Bottom Navigation:
├── Dashboard (overview)
├── All Complaints
├── Assign Complaints
├── Contractors
├── Chat Management
└── Settings
```

### 6. Security Rules Updates

#### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserRole() {
      return get(/databases/$(database)/documents/citizens/$(request.auth.uid)).data.role;
    }

    function isAdmin() {
      return isAuthenticated() && getUserRole() == 'admin';
    }

    function isContractor() {
      return isAuthenticated() && getUserRole() == 'contractor';
    }

    function isCitizen() {
      return isAuthenticated() && getUserRole() == 'citizen';
    }

    // Citizens collection
    match /citizens/{userId} {
      allow read: if isAuthenticated();
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId || isAdmin();
      allow delete: if isAdmin();
    }

    // Contractors collection
    match /contractors/{contractorId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // Complaints
    match /complaints/{complaintId} {
      allow read: if isAuthenticated();
      allow create: if isCitizen();
      allow update: if isAdmin() ||
                      (isContractor() && resource.data.assignedTo == request.auth.uid);
      allow delete: if isAdmin();
    }
  }
}
```

#### Realtime Database Rules

```json
{
  "rules": {
    "chats": {
      "$chatId": {
        ".read": "auth != null && (
          data.child('participants').child(auth.uid).exists() ||
          root.child('citizens').child(auth.uid).child('role').val() == 'admin'
        )",
        ".write": "auth != null && (
          data.child('participants').child(auth.uid).exists() ||
          root.child('citizens').child(auth.uid).child('role').val() == 'admin'
        )"
      }
    }
  }
}
```

## 📁 New File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── user_roles.dart           # NEW: Role definitions
│   └── utils/
│       └── role_helper.dart          # NEW: Role utilities
├── features/
│   ├── auth/
│   │   └── # Enhanced with role management
│   ├── admin/
│   │   ├── contractors/              # NEW: Contractor management
│   │   │   ├── screens/
│   │   │   │   ├── contractor_list_screen.dart
│   │   │   │   ├── create_contractor_screen.dart
│   │   │   │   └── contractor_detail_screen.dart
│   │   │   └── providers/
│   │   ├── assignment/               # NEW: Complaint assignment
│   │   │   ├── screens/
│   │   │   │   ├── assignment_screen.dart
│   │   │   │   └── assign_complaint_dialog.dart
│   │   │   └── providers/
│   │   └── dashboard/                # Enhanced admin dashboard
│   ├── contractor/                   # NEW: Contractor features
│   │   ├── dashboard/
│   │   │   ├── screens/
│   │   │   │   └── contractor_dashboard_screen.dart
│   │   │   └── providers/
│   │   ├── tasks/
│   │   │   ├── screens/
│   │   │   │   ├── assigned_tasks_screen.dart
│   │   │   │   └── task_detail_screen.dart
│   │   │   └── providers/
│   │   └── chat/
│   │       └── # Chat with admin
│   └── complaint/
│       └── # Enhanced with assignment fields
└── services/
    └── role_service.dart             # NEW: Role management service
```

## 🚀 Implementation Steps

### Phase 1: Foundation (Week 1)

1. ✅ Update user entity with role field
2. ✅ Create role constants and enums
3. ✅ Update authentication to handle roles
4. ✅ Create role service
5. ✅ Update database structure

### Phase 2: Admin Features (Week 2)

1. ✅ Create contractor management
2. ✅ Build assignment system
3. ✅ Enhanced admin dashboard
4. ✅ Update security rules

### Phase 3: Contractor Features (Week 3)

1. ✅ Contractor dashboard
2. ✅ Task management
3. ✅ Status updates
4. ✅ Contractor chat

### Phase 4: Integration (Week 4)

1. ✅ Update routing based on roles
2. ✅ Update existing features
3. ✅ Testing all roles
4. ✅ Documentation

### Phase 5: Migration (Week 5)

1. ✅ Data migration scripts
2. ✅ Default admin creation
3. ✅ Testing with real data
4. ✅ Deployment

## 📊 Migration Strategy

### Existing Users

```dart
// Migration script to add role to existing users
Future<void> migrateExistingUsers() async {
  final users = await FirebaseFirestore.instance
      .collection('citizens')
      .get();

  for (var doc in users.docs) {
    if (!doc.data().containsKey('role')) {
      await doc.reference.update({
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
```

### Default Admin

```dart
// Create default admin in Firebase Console or seed script
{
  "email": "admin@srscs.com",
  "role": "admin",
  "fullName": "System Administrator",
  "createdAt": serverTimestamp
}
```

## ⚠️ Breaking Changes

1. **User Entity**: Added role field (backward compatible with migration)
2. **Login Flow**: Routes to different dashboards based on role
3. **Complaint Entity**: Added assignment fields
4. **Chat Structure**: Changed to support contractor-admin chats

## 🧪 Testing Checklist

### Citizen

- [ ] Register new account
- [ ] Submit complaint
- [ ] Track complaints
- [ ] Chat with admin
- [ ] Cannot access admin/contractor features

### Contractor

- [ ] Login with credentials
- [ ] View only assigned complaints
- [ ] Update complaint status
- [ ] Chat with admin
- [ ] Cannot access admin features
- [ ] Cannot see other contractors' tasks

### Admin

- [ ] Login with admin credentials
- [ ] View all complaints
- [ ] Create contractor accounts
- [ ] Assign complaints to contractors
- [ ] Reassign complaints
- [ ] Chat with citizens and contractors
- [ ] View all system data

## 📝 Documentation Updates

- [ ] Update README with role-based features
- [ ] Create admin user guide
- [ ] Create contractor user guide
- [ ] Update API documentation
- [ ] Create deployment guide

## 🔐 Security Considerations

1. **Role Verification**: Always verify role on backend
2. **UI Hiding**: Hide features in UI based on role
3. **API Protection**: Protect all admin/contractor endpoints
4. **Audit Logging**: Log all admin actions
5. **Contractor Scope**: Restrict contractors to assigned area

## 🎨 UI/UX Guidelines

### Color Coding by Role

- **Citizen**: Purple (#9F7AEA)
- **Contractor**: Blue (#4299E1)
- **Admin**: Red (#F56565)

### Navigation Patterns

- Role-specific bottom navigation
- Role badge in app bar
- Clear visual distinction

---

**Implementation Start Date**: October 22, 2025  
**Estimated Completion**: 5 weeks  
**Priority**: High  
**Status**: Planning Complete ✅
