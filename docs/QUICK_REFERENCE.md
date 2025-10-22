# Quick Reference - Role-Based System

## 🚀 Quick Start

### Check User Role

```dart
import 'package:srscs/core/constants/user_roles.dart';
import 'package:srscs/core/utils/role_helper.dart';

// Get current user's role
UserRole? role = await authService.getUserRole(userId);

// Check permissions
if (role?.canAssignComplaints ?? false) {
  // Show assignment feature
}

// Get dashboard route
String route = RoleHelper.getDashboardRoute(role!);
Navigator.pushNamed(context, route);
```

### Display Role Badge

```dart
// Show role badge in UI
RoleHelper.buildRoleBadge(
  UserRole.contractor,
  fontSize: 14,
);
```

### Check Permissions

```dart
// Can perform action on complaint?
bool canUpdate = RoleHelper.canPerformComplaintAction(
  userRole: UserRole.contractor,
  action: 'updateStatus',
  complainantId: complaint.userId,
  assignedTo: complaint.assignedTo,
  userId: currentUserId,
);
```

## 📊 Database Queries

### Get Contractor's Tasks

```dart
FirebaseFirestore.instance
  .collection('complaints')
  .where('assignedTo', isEqualTo: contractorId)
  .orderBy('assignedAt', descending: true)
  .snapshots();
```

### Get Unassigned Complaints by Area

```dart
FirebaseFirestore.instance
  .collection('complaints')
  .where('area', isEqualTo: 'Dhaka-North')
  .where('assignedTo', isNull: true)
  .orderBy('createdAt', descending: true)
  .snapshots();
```

### Get Active Contractors in Area

```dart
FirebaseFirestore.instance
  .collection('contractors')
  .where('assignedArea', isEqualTo: 'Dhaka-North')
  .where('isActive', isEqualTo: true)
  .snapshots();
```

## 🎨 UI Components

### Navigation by Role

```dart
List<NavigationItem> items = RoleHelper.getNavigationItems(userRole);

BottomNavigationBar(
  items: items.map((item) => BottomNavigationBarItem(
    icon: Icon(item.icon),
    label: item.label,
  )).toList(),
  onTap: (index) {
    Navigator.pushNamed(context, items[index].route);
  },
);
```

### Status Chip

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: status.color.withOpacity(0.1),
    border: Border.all(color: status.color),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(status.icon, size: 14, color: status.color),
      SizedBox(width: 4),
      Text(status.displayName, style: TextStyle(color: status.color)),
    ],
  ),
);
```

## 🔐 Security Examples

### Check Route Access

```dart
// In navigation guard
bool canAccess = RoleHelper.canAccessRoute(
  userRole,
  '/admin/contractors',
);

if (!canAccess) {
  Navigator.pushReplacementNamed(context, '/unauthorized');
}
```

### Firestore Rule Pattern

```javascript
// Check if user is admin
function isAdmin() {
  return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

// Check if user can read complaint
function canReadComplaint() {
  return resource.data.userId == request.auth.uid ||
         isAdmin() ||
         (isContractor() && resource.data.assignedTo == request.auth.uid);
}
```

## 📝 Common Patterns

### Assign Complaint

```dart
Future<void> assignComplaint(String complaintId, String contractorId) async {
  await FirebaseFirestore.instance
    .collection('complaints')
    .doc(complaintId)
    .update({
      'assignedTo': contractorId,
      'assignedBy': currentAdminId,
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'inProgress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

  // Send notification to contractor
  await sendNotification(contractorId, 'New task assigned');
}
```

### Mark Complaint Completed

```dart
Future<void> markCompleted(String complaintId, String notes) async {
  await FirebaseFirestore.instance
    .collection('complaints')
    .doc(complaintId)
    .update({
      'status': 'resolved',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'contractorNotes': notes,
    });

  // Notify citizen and admin
  await notifyCompletion(complaintId);
}
```

### Create Contractor Account

```dart
Future<String?> createContractor({
  required String email,
  required String password,
  required String fullName,
  required String phone,
  required String area,
}) async {
  // Create auth account
  final userCred = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(email: email, password: password);

  final contractorId = userCred.user!.uid;

  // Create contractor document
  await FirebaseFirestore.instance
    .collection('contractors')
    .doc(contractorId)
    .set({
      'email': email,
      'fullName': fullName,
      'phoneNumber': phone,
      'assignedArea': area,
      'createdBy': currentAdminId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'role': 'contractor',
    });

  return contractorId;
}
```

## 🎯 Areas List

```dart
const availableAreas = [
  'Dhaka-North',
  'Dhaka-South',
  'Dhaka-Central',
  'Chittagong-North',
  'Chittagong-South',
  'Sylhet',
  'Rajshahi',
  'Khulna',
  'Barisal',
  'Rangpur',
  'Mymensingh',
];
```

## 🔔 Notifications

### Notify on Assignment

```dart
Future<void> notifyAssignment(String contractorId, String complaintId) async {
  await FirebaseMessaging.instance.sendMessage(
    to: contractorId,
    data: {
      'type': 'task_assigned',
      'complaintId': complaintId,
      'title': 'New Task Assigned',
      'body': 'You have been assigned a new complaint',
    },
  );
}
```

### Notify on Completion

```dart
Future<void> notifyCompletion(String complaintId) async {
  final complaint = await getComplaint(complaintId);

  // Notify citizen
  await sendNotification(
    complaint.userId,
    'Complaint Resolved',
    'Your complaint has been resolved',
  );

  // Notify admin
  await sendNotification(
    adminId,
    'Task Completed',
    'Contractor completed the task',
  );
}
```

## 📊 Statistics Queries

### Contractor Performance

```dart
Future<Map<String, int>> getContractorStats(String contractorId) async {
  final complaints = await FirebaseFirestore.instance
    .collection('complaints')
    .where('assignedTo', isEqualTo: contractorId)
    .get();

  int total = complaints.docs.length;
  int completed = complaints.docs
    .where((doc) => doc.data()['status'] == 'resolved')
    .length;
  int pending = complaints.docs
    .where((doc) => doc.data()['status'] == 'inProgress')
    .length;

  return {
    'total': total,
    'completed': completed,
    'pending': pending,
    'completionRate': completed > 0 ? (completed / total * 100).round() : 0,
  };
}
```

### Admin Dashboard Stats

```dart
Future<Map<String, int>> getSystemStats() async {
  final complaints = await FirebaseFirestore.instance
    .collection('complaints')
    .get();

  return {
    'total': complaints.docs.length,
    'pending': complaints.docs.where((d) => d['status'] == 'pending').length,
    'assigned': complaints.docs.where((d) => d['assignedTo'] != null).length,
    'completed': complaints.docs.where((d) => d['status'] == 'resolved').length,
  };
}
```

## 🛠️ Utility Functions

### Parse User Role

```dart
UserRole? role = parseUserRole('contractor'); // Returns UserRole.contractor
```

### Validate Contractor Data

```dart
String? error = RoleHelper.validateContractorData(
  email: email,
  fullName: fullName,
  phone: phone,
  area: area,
);

if (error != null) {
  // Show error
}
```

### Get Statistics Label

```dart
String label = RoleHelper.getStatisticsLabel(
  UserRole.contractor,
  'total',
); // Returns "Assigned Tasks"
```

## 📱 Screen Navigation

### Route to Dashboard

```dart
// After login
UserRole role = await getUserRole(userId);
String route = RoleHelper.getDashboardRoute(role);
Navigator.pushReplacementNamed(context, route);
```

### Available Routes

```dart
// Citizen
'/dashboard'
'/submit-complaint'
'/track-complaints'
'/chat'
'/profile'

// Contractor
'/contractor/dashboard'
'/contractor/tasks'
'/contractor/completed'
'/contractor/chat'

// Admin
'/admin/dashboard'
'/admin/complaints'
'/admin/assign'
'/admin/contractors'
'/admin/chat'
```

## 🎨 Color Constants

```dart
// Role Colors
const citizenColor = Color(0xFF9F7AEA);    // Purple
const contractorColor = Color(0xFF4299E1); // Blue
const adminColor = Color(0xFFF56565);      // Red

// Status Colors
const pendingColor = Colors.orange;
const inProgressColor = Colors.purple;
const resolvedColor = Colors.green;
const rejectedColor = Colors.red;
```

## 🔍 Debugging

### Check User Collection

```dart
// Determine which collection user is in
Future<String> getUserCollection(String userId) async {
  final citizen = await FirebaseFirestore.instance
    .collection('citizens')
    .doc(userId)
    .get();

  if (citizen.exists) return 'citizens';

  final contractor = await FirebaseFirestore.instance
    .collection('contractors')
    .doc(userId)
    .get();

  if (contractor.exists) return 'contractors';

  final admin = await FirebaseFirestore.instance
    .collection('admins')
    .doc(userId)
    .get();

  if (admin.exists) return 'admins';

  return 'unknown';
}
```

---

**For detailed implementation, see:**

- `docs/IMPLEMENTATION_GUIDE.md`
- `docs/ARCHITECTURE_DIAGRAM.md`
- `docs/ROLE_BASED_SYSTEM_PLAN.md`
