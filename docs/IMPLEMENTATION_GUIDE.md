# Role-Based System Implementation Guide

## 🎯 Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)
- [x] Updated ComplaintEntity with assignment fields
- [x] Updated ComplaintModel with Firestore serialization
- [x] Created role constants (user_roles.dart)
- [x] Created role helper utilities (role_helper.dart)
- [x] Created ContractorEntity and ContractorModel

### 📝 Phase 2: Core Services (NEXT STEPS)

#### Step 1: Create Contractor Service
Create `lib/services/contractor_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/contractor/data/models/contractor_model.dart';

class ContractorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin creates contractor account
  Future<String?> createContractor({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String assignedArea,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final contractorId = userCredential.user!.uid;

      // Create contractor document
      final contractor = ContractorModel(
        id: contractorId,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        assignedArea: assignedArea,
        createdBy: _auth.currentUser!.uid, // Current admin
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('contractors')
          .doc(contractorId)
          .set(contractor.toFirestore());

      return contractorId;
    } catch (e) {
      throw Exception('Failed to create contractor: $e');
    }
  }

  // Get all contractors
  Stream<List<ContractorModel>> getAllContractors() {
    return _firestore
        .collection('contractors')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractorModel.fromFirestore(doc))
            .toList());
  }

  // Get contractors by area
  Stream<List<ContractorModel>> getContractorsByArea(String area) {
    return _firestore
        .collection('contractors')
        .where('assignedArea', isEqualTo: area)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractorModel.fromFirestore(doc))
            .toList());
  }

  // Toggle contractor active status
  Future<void> toggleContractorStatus(String contractorId) async {
    final doc = await _firestore.collection('contractors').doc(contractorId).get();
    final currentStatus = doc.data()?['isActive'] ?? true;
    
    await _firestore
        .collection('contractors')
        .doc(contractorId)
        .update({'isActive': !currentStatus});
  }

  // Update contractor area
  Future<void> updateContractorArea(String contractorId, String newArea) async {
    await _firestore
        .collection('contractors')
        .doc(contractorId)
        .update({'assignedArea': newArea});
  }
}
```

#### Step 2: Create Assignment Service
Create `lib/services/assignment_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Assign complaint to contractor
  Future<void> assignComplaint({
    required String complaintId,
    required String contractorId,
  }) async {
    final adminId = _auth.currentUser!.uid;
    
    await _firestore.collection('complaints').doc(complaintId).update({
      'assignedTo': contractorId,
      'assignedBy': adminId,
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'inProgress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // TODO: Send notification to contractor
  }

  // Reassign complaint
  Future<void> reassignComplaint({
    required String complaintId,
    required String newContractorId,
  }) async {
    await assignComplaint(
      complaintId: complaintId,
      contractorId: newContractorId,
    );
  }

  // Mark complaint as completed by contractor
  Future<void> markComplaintCompleted({
    required String complaintId,
    String? contractorNotes,
  }) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': 'resolved',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (contractorNotes != null) 'contractorNotes': contractorNotes,
    });

    // TODO: Send notification to user and admin
  }

  // Get unassigned complaints for an area
  Stream<QuerySnapshot> getUnassignedComplaintsByArea(String area) {
    return _firestore
        .collection('complaints')
        .where('area', isEqualTo: area)
        .where('assignedTo', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get contractor's assigned complaints
  Stream<QuerySnapshot> getContractorComplaints(String contractorId) {
    return _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: contractorId)
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }
}
```

#### Step 3: Update Auth Service
Modify `lib/services/auth_service.dart` to handle role-based routing:

```dart
// Add this method to your existing AuthService

import '../core/constants/user_roles.dart';

Future<UserRole?> getUserRole(String userId) async {
  try {
    // Check in citizens collection first
    final citizenDoc = await _firestore.collection('citizens').doc(userId).get();
    if (citizenDoc.exists) {
      final roleStr = citizenDoc.data()?['role'] as String?;
      return parseUserRole(roleStr ?? 'citizen');
    }

    // Check in contractors collection
    final contractorDoc = await _firestore.collection('contractors').doc(userId).get();
    if (contractorDoc.exists) {
      return UserRole.contractor;
    }

    // Check in admins collection
    final adminDoc = await _firestore.collection('admins').doc(userId).get();
    if (adminDoc.exists) {
      return UserRole.admin;
    }

    return UserRole.citizen; // Default
  } catch (e) {
    return null;
  }
}
```

### 📱 Phase 3: UI Screens

#### A. Contractor Management (Admin)

**1. Contractor List Screen**
Path: `lib/features/admin/contractors/screens/contractor_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../services/contractor_service.dart';
import '../../../../core/constants/user_roles.dart';

class ContractorListScreen extends StatelessWidget {
  final ContractorService _contractorService = ContractorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contractors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/contractors/create');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ContractorModel>>(
        stream: _contractorService.getAllContractors(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contractors = snapshot.data!;

          if (contractors.isEmpty) {
            return const Center(
              child: Text('No contractors yet. Create one!'),
            );
          }

          return ListView.builder(
            itemCount: contractors.length,
            itemBuilder: (context, index) {
              final contractor = contractors[index];
              return ContractorCard(contractor: contractor);
            },
          );
        },
      ),
    );
  }
}
```

**2. Create Contractor Screen**
Path: `lib/features/admin/contractors/screens/create_contractor_screen.dart`

```dart
// Form to create new contractor with:
// - Email
// - Password (generated or manual)
// - Full Name
// - Phone Number
// - Assigned Area (dropdown)
```

**3. Contractor Detail Screen**
Path: `lib/features/admin/contractors/screens/contractor_detail_screen.dart`

```dart
// Show contractor details:
// - Personal info
// - Assigned area
// - Statistics (total assigned, completed, pending)
// - Recent tasks
// - Toggle active/inactive
```

#### B. Complaint Assignment (Admin)

**Assignment Screen**
Path: `lib/features/admin/assignment/screens/assignment_screen.dart`

```dart
// Two-column layout:
// Left: Unassigned complaints list (filtered by area)
// Right: Available contractors in that area
// Drag & drop or button to assign
```

#### C. Contractor Dashboard

**Contractor Dashboard Screen**
Path: `lib/features/contractor/dashboard/screens/contractor_dashboard_screen.dart`

```dart
// Dashboard showing:
// - Statistics (assigned, in-progress, completed)
// - Map with assigned complaint locations
// - Recent tasks
// - Quick actions
```

**Task Detail Screen**
Path: `lib/features/contractor/tasks/screens/task_detail_screen.dart`

```dart
// Complaint details with:
// - User info
// - Location
// - Description and media
// - Status update buttons
// - Add notes
// - Mark as completed button
// - Upload completion photos
```

#### D. Enhanced Admin Dashboard

**Admin Dashboard Screen**
Path: `lib/features/admin/dashboard/screens/admin_dashboard_screen.dart`

```dart
// Overview showing:
// - Total complaints (all status)
// - Pending assignments
// - Active contractors
// - Area-wise breakdown
// - Recent activity
// - Charts and graphs
```

### 🔐 Phase 4: Security Rules

#### Firestore Rules
Update `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserRole(userId) {
      return get(/databases/$(database)/documents/citizens/$(userId)).data.role;
    }
    
    function isAdmin(userId) {
      return getUserRole(userId) == 'admin' ||
             exists(/databases/$(database)/documents/admins/$(userId));
    }
    
    function isContractor(userId) {
      return exists(/databases/$(database)/documents/contractors/$(userId));
    }
    
    // Citizens collection
    match /citizens/{userId} {
      allow read: if isAuthenticated();
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId || isAdmin(request.auth.uid);
      allow delete: if isAdmin(request.auth.uid);
    }
    
    // Contractors collection
    match /contractors/{contractorId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin(request.auth.uid);
    }
    
    // Admins collection
    match /admins/{adminId} {
      allow read: if isAdmin(request.auth.uid);
      allow write: if false; // Only through Firebase Console
    }
    
    // Complaints
    match /complaints/{complaintId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        isAdmin(request.auth.uid) ||
        (isContractor(request.auth.uid) && resource.data.assignedTo == request.auth.uid)
      );
      
      allow create: if isAuthenticated() && request.auth.uid == request.resource.data.userId;
      
      allow update: if isAuthenticated() && (
        isAdmin(request.auth.uid) ||
        (isContractor(request.auth.uid) && resource.data.assignedTo == request.auth.uid)
      );
      
      allow delete: if isAdmin(request.auth.uid);
    }
  }
}
```

#### Realtime Database Rules
Update `database.rules.json`:

```json
{
  "rules": {
    "chats": {
      "$chatId": {
        ".read": "auth != null && (
          data.child('participants').child(auth.uid).exists() ||
          root.child('admins').child(auth.uid).exists()
        )",
        ".write": "auth != null && (
          data.child('participants').child(auth.uid).exists() ||
          root.child('admins').child(auth.uid).exists()
        )",
        "messages": {
          "$messageId": {
            ".validate": "newData.hasChildren(['senderId', 'text', 'timestamp'])"
          }
        }
      }
    }
  }
}
```

### 🔄 Phase 5: Migration

#### Create Default Admin
Run this in Firebase Console > Firestore:

1. Create user in Authentication:
   - Email: `admin@srscs.com`
   - Password: (set a strong password)
   - Copy the UID

2. Create document in `admins` collection:
```json
{
  "email": "admin@srscs.com",
  "fullName": "System Administrator",
  "role": "admin",
  "createdAt": {serverTimestamp}
}
```

3. Also add to `citizens` collection (for backward compatibility):
```json
{
  "email": "admin@srscs.com",
  "fullName": "System Administrator",
  "role": "admin",
  "createdAt": {serverTimestamp}
}
```

#### Migrate Existing Users
Create `lib/utils/migration_script.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateExistingUsers() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Get all citizens
    final citizens = await firestore.collection('citizens').get();
    
    for (var doc in citizens.docs) {
      final data = doc.data();
      
      // Add role field if missing
      if (!data.containsKey('role')) {
        await doc.reference.update({
          'role': 'citizen',
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        });
        print('Migrated user: ${doc.id}');
      }
    }
    
    print('Migration completed successfully!');
  } catch (e) {
    print('Migration error: $e');
  }
}
```

### 🧪 Testing Checklist

#### Create Test Accounts

1. **Admin Account**
   - Email: admin@srscs.com
   - Password: Admin123!
   - Role: admin

2. **Contractor Account**
   - Email: contractor1@srscs.com
   - Password: Contractor123!
   - Area: Dhaka-North
   - Role: contractor

3. **Citizen Account**
   - Email: citizen@test.com
   - Password: Citizen123!
   - Role: citizen

#### Test Scenarios

**As Citizen:**
- [ ] Register new account
- [ ] Submit complaint with area
- [ ] View own complaints
- [ ] Cannot access admin/contractor routes
- [ ] Chat with admin

**As Contractor:**
- [ ] Login with credentials
- [ ] View only assigned complaints
- [ ] Update complaint status to in-progress
- [ ] Add contractor notes
- [ ] Mark complaint as completed
- [ ] Upload completion photos
- [ ] Chat with admin
- [ ] Cannot access admin routes

**As Admin:**
- [ ] View all complaints
- [ ] Filter complaints by area
- [ ] Create new contractor account
- [ ] View all contractors
- [ ] Assign complaint to contractor
- [ ] Reassign complaint
- [ ] View contractor statistics
- [ ] Deactivate contractor
- [ ] Chat with citizens and contractors
- [ ] Access all routes

### 📊 Database Structure

```
Firestore:
├── citizens/
│   └── {userId}
│       ├── email
│       ├── fullName
│       ├── role: "citizen"
│       ├── nid
│       ├── phone
│       └── createdAt
│
├── contractors/
│   └── {contractorId}
│       ├── email
│       ├── fullName
│       ├── phoneNumber
│       ├── assignedArea
│       ├── createdBy (adminId)
│       ├── createdAt
│       ├── isActive
│       └── role: "contractor"
│
├── admins/
│   └── {adminId}
│       ├── email
│       ├── fullName
│       ├── role: "admin"
│       └── createdAt
│
└── complaints/
    └── {complaintId}
        ├── userId
        ├── userName
        ├── type
        ├── description
        ├── area (NEW)
        ├── location
        ├── status
        ├── assignedTo (NEW)
        ├── assignedBy (NEW)
        ├── assignedAt (NEW)
        ├── completedAt (NEW)
        ├── contractorNotes (NEW)
        ├── adminNotes
        └── timestamps

Realtime Database:
└── chats/
    ├── citizen-admin-{citizenId}/
    │   ├── participants: {citizenId, adminId}
    │   ├── participantRoles: {citizenId: "citizen", adminId: "admin"}
    │   └── messages/
    └── contractor-admin-{contractorId}/
        ├── participants: {contractorId, adminId}
        ├── participantRoles: {contractorId: "contractor", adminId: "admin"}
        └── messages/
```

### 🚀 Deployment Steps

1. **Update Database Structure**
   - Run migration script
   - Create default admin
   - Update security rules

2. **Test Locally**
   - Test all three user roles
   - Verify permissions
   - Test assignment flow

3. **Deploy to Production**
   - Deploy security rules
   - Deploy functions (if any)
   - Create production admin account

4. **Monitor**
   - Check error logs
   - Monitor user complaints
   - Track contractor performance

---

**Next Steps:**
1. Implement contractor service ✅ (Created models)
2. Create contractor management screens
3. Build assignment system
4. Update auth flow
5. Test thoroughly

**Current Files Created:**
- ✅ `lib/core/constants/user_roles.dart`
- ✅ `lib/core/utils/role_helper.dart`
- ✅ `lib/features/complaint/domain/entities/complaint_entity.dart` (updated)
- ✅ `lib/features/complaint/data/models/complaint_model.dart` (updated)
- ✅ `lib/features/contractor/domain/entities/contractor_entity.dart`
- ✅ `lib/features/contractor/data/models/contractor_model.dart`

**Files to Create Next:**
- `lib/services/contractor_service.dart`
- `lib/services/assignment_service.dart`
- Admin contractor management screens
- Contractor dashboard screens
- Enhanced admin dashboard
