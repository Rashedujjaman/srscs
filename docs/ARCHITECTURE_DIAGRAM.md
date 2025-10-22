# Role-Based System Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      SRSCS Mobile App                           │
│                  (Single Application)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Login
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Role Detection                               │
│              Check user role from Firestore                     │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ↓                     ↓                     ↓
┌──────────────┐    ┌──────────────┐      ┌──────────────┐
│   CITIZEN    │    │  CONTRACTOR  │      │    ADMIN     │
│   (Purple)   │    │    (Blue)    │      │    (Red)     │
└──────────────┘    └──────────────┘      └──────────────┘
```

## User Roles & Permissions

```
┌─────────────────────────────────────────────────────────────────┐
│                         CITIZEN                                 │
├─────────────────────────────────────────────────────────────────┤
│ Can:                                                            │
│ ✓ Self-register                                                │
│ ✓ Submit complaints                                            │
│ ✓ Track own complaints                                         │
│ ✓ Chat with admin                                              │
│ ✓ Update own profile                                           │
│                                                                 │
│ Cannot:                                                         │
│ ✗ View others' complaints                                      │
│ ✗ Assign complaints                                            │
│ ✗ Create contractors                                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       CONTRACTOR                                │
├─────────────────────────────────────────────────────────────────┤
│ Can:                                                            │
│ ✓ View assigned complaints only                                │
│ ✓ Update complaint status                                      │
│ ✓ Add contractor notes                                         │
│ ✓ Upload completion photos                                     │
│ ✓ Chat with admin                                              │
│ ✓ Mark complaints as completed                                 │
│                                                                 │
│ Cannot:                                                         │
│ ✗ Self-register (admin creates)                                │
│ ✗ View unassigned complaints                                   │
│ ✗ Assign complaints                                            │
│ ✗ Delete complaints                                            │
│                                                                 │
│ Area Assignment: Required                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          ADMIN                                  │
├─────────────────────────────────────────────────────────────────┤
│ Full System Access:                                             │
│ ✓ View ALL complaints                                          │
│ ✓ Create contractor accounts                                   │
│ ✓ Assign/reassign complaints                                   │
│ ✓ Manage all users                                             │
│ ✓ Chat with everyone                                           │
│ ✓ View system analytics                                        │
│ ✓ Activate/deactivate contractors                              │
│ ✓ Update any complaint                                         │
│                                                                 │
│ Creation: Manual (Firebase Console)                            │
└─────────────────────────────────────────────────────────────────┘
```

## Complaint Flow

```
┌──────────────┐
│   CITIZEN    │
│  Submits     │
│  Complaint   │
└──────┬───────┘
       │
       │ Creates complaint with area/location
       ↓
┌─────────────────────────────────────┐
│        FIRESTORE                    │
│     complaints collection           │
│  ┌─────────────────────────────┐   │
│  │ status: "pending"           │   │
│  │ area: "Dhaka-North"         │   │
│  │ assignedTo: null            │   │
│  └─────────────────────────────┘   │
└─────────────┬───────────────────────┘
              │
              │ Admin reviews
              ↓
┌──────────────────────────────────────┐
│           ADMIN                      │
│  Views pending complaints            │
│  Filters by area                     │
│  Selects contractor in that area     │
└──────────────┬───────────────────────┘
               │
               │ Assigns
               ↓
┌─────────────────────────────────────┐
│        FIRESTORE (Updated)          │
│  ┌─────────────────────────────┐   │
│  │ status: "inProgress"        │   │
│  │ area: "Dhaka-North"         │   │
│  │ assignedTo: contractorId    │   │
│  │ assignedBy: adminId         │   │
│  │ assignedAt: timestamp       │   │
│  └─────────────────────────────┘   │
└─────────────┬───────────────────────┘
              │
              │ Notification sent
              ↓
┌──────────────────────────────────────┐
│        CONTRACTOR                    │
│  Views in dashboard                  │
│  Updates status to "inProgress"      │
│  Works on complaint                  │
│  Adds notes & photos                 │
│  Marks as "completed"                │
└──────────────┬───────────────────────┘
               │
               │ Updates
               ↓
┌─────────────────────────────────────┐
│        FIRESTORE (Final)            │
│  ┌─────────────────────────────┐   │
│  │ status: "resolved"          │   │
│  │ completedAt: timestamp      │   │
│  │ contractorNotes: "..."      │   │
│  └─────────────────────────────┘   │
└─────────────┬───────────────────────┘
              │
              │ Notifications sent
              ↓
      ┌───────┴────────┐
      │                │
      ↓                ↓
┌──────────┐    ┌──────────┐
│ CITIZEN  │    │  ADMIN   │
│ Notified │    │ Notified │
└──────────┘    └──────────┘
```

## Database Architecture

```
Firebase Firestore
├── citizens/
│   └── {userId}
│       ├── email: string
│       ├── fullName: string
│       ├── role: "citizen"
│       ├── nid: string
│       ├── phone: string
│       └── createdAt: timestamp
│
├── contractors/
│   └── {contractorId}
│       ├── email: string
│       ├── fullName: string
│       ├── phoneNumber: string
│       ├── assignedArea: "Dhaka-North"
│       ├── createdBy: adminId
│       ├── createdAt: timestamp
│       ├── isActive: true
│       └── role: "contractor"
│
├── admins/
│   └── {adminId}
│       ├── email: string
│       ├── fullName: string
│       ├── role: "admin"
│       └── createdAt: timestamp
│
└── complaints/
    └── {complaintId}
        ├── userId: citizenId
        ├── userName: string
        ├── type: enum
        ├── description: string
        ├── area: "Dhaka-North" ← NEW
        ├── location: {lat, lng}
        ├── status: enum
        ├── assignedTo: contractorId ← NEW
        ├── assignedBy: adminId ← NEW
        ├── assignedAt: timestamp ← NEW
        ├── completedAt: timestamp ← NEW
        ├── contractorNotes: string ← NEW
        ├── adminNotes: string
        └── timestamps

Firebase Realtime Database
└── chats/
    ├── citizen-admin-{citizenId}/
    │   ├── participants/
    │   │   ├── {citizenId}: true
    │   │   └── {adminId}: true
    │   ├── participantRoles/
    │   │   ├── {citizenId}: "citizen"
    │   │   └── {adminId}: "admin"
    │   └── messages/
    │
    └── contractor-admin-{contractorId}/
        ├── participants/
        │   ├── {contractorId}: true
        │   └── {adminId}: true
        ├── participantRoles/
        │   ├── {contractorId}: "contractor"
        │   └── {adminId}: "admin"
        └── messages/
```

## Navigation Structure

```
CITIZEN Navigation
┌────────────────────────────────────┐
│  Dashboard  │  Submit  │  Track   │
│             │          │           │
│  Chat       │        Profile      │
└────────────────────────────────────┘

CONTRACTOR Navigation
┌────────────────────────────────────┐
│ Dashboard   │  Tasks  │ Completed │
│             │         │           │
│    Chat     │      Profile        │
└────────────────────────────────────┘

ADMIN Navigation
┌────────────────────────────────────┐
│ Dashboard   │ Complaints │ Assign │
│             │            │        │
│ Contractors │    Chat Management  │
└────────────────────────────────────┘
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                  Firebase Security Rules                     │
└─────────────────────────────────────────────────────────────┘
                          │
       ┌──────────────────┼──────────────────┐
       │                  │                  │
       ↓                  ↓                  ↓
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Firestore  │   │  Realtime   │   │   Storage   │
│    Rules    │   │     DB      │   │    Rules    │
└─────────────┘   └─────────────┘   └─────────────┘
       │                  │                  │
       └──────────────────┴──────────────────┘
                          │
                          ↓
              ┌───────────────────────┐
              │  Permission Checks    │
              ├───────────────────────┤
              │ • Is authenticated?   │
              │ • What is user role?  │
              │ • Owns this data?     │
              │ • Assigned to this?   │
              │ • Is admin?           │
              └───────────────────────┘
```

## Area-Based Assignment

```
Bangladesh Areas
├── Dhaka-North     → Contractor-1, Contractor-2
├── Dhaka-South     → Contractor-3
├── Dhaka-Central   → Contractor-4
├── Chittagong-N    → Contractor-5
├── Chittagong-S    → Contractor-6
├── Sylhet          → Contractor-7
├── Rajshahi        → Contractor-8
├── Khulna          → Contractor-9
├── Barisal         → Contractor-10
├── Rangpur         → Contractor-11
└── Mymensingh      → Contractor-12

Assignment Logic:
1. Complaint submitted with location
2. System determines area from location
3. Admin views contractors in that area
4. Admin assigns to available contractor
5. Contractor notified and accepts
```

## API Flow

```
Registration Flow
─────────────────
Citizen:
  User fills form → Firebase Auth createUser
                 → Create Firestore doc in citizens/
                 → role: "citizen"
                 → Redirect to citizen dashboard

Contractor:
  Admin fills form → Firebase Auth createUser (by admin)
                  → Create Firestore doc in contractors/
                  → role: "contractor"
                  → assignedArea: selected
                  → createdBy: adminId
                  → Send credentials email

Admin:
  Manual creation in Firebase Console
  → Add to Firebase Auth
  → Create doc in admins/ collection
  → role: "admin"

Login Flow
──────────
User enters credentials
  ↓
Firebase Auth signIn
  ↓
Fetch user document from Firestore
  ↓
Determine role (citizen/contractor/admin)
  ↓
Route to appropriate dashboard
  ↓
Load role-specific navigation & features
```

## Color Coding

```
Role Colors (for UI distinction)
────────────────────────────────

Citizen:     Purple  #9F7AEA  ████
Contractor:  Blue    #4299E1  ████
Admin:       Red     #F56565  ████

Status Colors
─────────────

Pending:      Orange  #ED8936  ████
Under Review: Blue    #4299E1  ████
In Progress:  Purple  #9F7AEA  ████
Resolved:     Green   #48BB78  ████
Rejected:     Red     #F56565  ████
```

## Timeline

```
Week 1-2: Services & Backend
├── ContractorService
├── AssignmentService
├── Update AuthService
└── Security Rules

Week 2-3: UI Screens
├── Admin: Contractor Management
├── Admin: Assignment System
├── Contractor: Dashboard & Tasks
└── Update existing screens

Week 3-4: Integration
├── Role-based routing
├── Permission system
├── Chat enhancement
└── Testing

Week 4-5: Migration & Deployment
├── Data migration
├── Create default admin
├── Production deployment
└── Monitoring setup
```

---

**Legend:**

- → : Data flow
- ↓ : Process flow
- ├─ : Tree structure
- ✓ : Allowed
- ✗ : Not allowed
- ← : New field
