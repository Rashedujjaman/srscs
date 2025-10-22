# Login Testing Guide

## Overview

The login system now supports **role-based authentication** with automatic redirection to the appropriate dashboard based on user role (Citizen, Contractor, or Admin).

## What Was Changed

### 1. **Updated Login Screen** (`login_screen.dart`)

- ✅ Added `AuthService` integration to check user role after login
- ✅ Improved error messages for different Firebase Auth errors
- ✅ Added role-based dashboard redirection
- ✅ Shows role in success message (e.g., "Login Successful as Admin")
- ✅ Better error handling for invalid credentials

**Error Messages:**

- `user-not-found` → "No user found with this email."
- `wrong-password` → "Incorrect password. Please try again."
- `invalid-email` → "Invalid email format."
- `user-disabled` → "This account has been disabled."
- `invalid-credential` → "Invalid credentials. Please check your email and password."

### 2. **Created Splash Screen** (`splash_screen.dart`)

- ✅ Automatically checks if user is already logged in
- ✅ Fetches user role from Firestore
- ✅ Redirects to appropriate dashboard based on role
- ✅ Shows loading animation during check
- ✅ Handles edge cases (user with no role, auth errors)

### 3. **Updated Main.dart**

- ✅ Added splash screen as initial route (`/`)
- ✅ Imported splash screen component
- ✅ Removed hardcoded citizen dashboard redirect

## Login Flow

```
App Launch
    ↓
Splash Screen (2 seconds)
    ↓
Check Firebase Auth
    ├─ Not Authenticated → Login Screen
    └─ Authenticated
         ↓
         Fetch User Role from Firestore
         ├─ Role: citizen → Citizen Dashboard (/dashboard)
         ├─ Role: contractor → Contractor Dashboard (/contractor/dashboard)
         ├─ Role: admin → Admin Dashboard (/admin/dashboard)
         └─ No Role Found → Logout & Login Screen
```

## Testing Instructions

### Step 1: Prepare Test Accounts in Firestore

You mentioned you've already created admin and contractor accounts. Ensure they have this structure:

**Admin Collection** (`admins/{userId}`)

```json
{
  "email": "admin@test.com",
  "fullName": "Admin User",
  "role": "admin",
  "createdAt": "timestamp"
}
```

**Contractor Collection** (`contractors/{userId}`)

```json
{
  "email": "contractor@test.com",
  "fullName": "Test Contractor",
  "phoneNumber": "01712345678",
  "assignedArea": "Dhaka",
  "isActive": true,
  "createdBy": "adminUserId",
  "createdAt": "timestamp",
  "role": "contractor"
}
```

**Citizen Collection** (`citizens/{userId}`)

```json
{
  "email": "citizen@test.com",
  "fullName": "Test Citizen",
  "nid": "1234567890",
  "phoneNumber": "01712345678",
  "address": "Test Address",
  "role": "citizen"
}
```

### Step 2: Test Login Process

1. **Launch the app**

   - You should see the splash screen with logo and "Loading..."
   - After 2 seconds, it will check authentication

2. **First Time (Not Logged In)**

   - Redirects to Login Screen
   - Enter credentials for any role
   - Click "Login"

3. **Test Admin Login**

   ```
   Email: admin@test.com
   Password: [your password]
   ```

   - Expected: "Login Successful as Admin"
   - Redirects to: Admin Dashboard (/admin/dashboard)

4. **Test Contractor Login**

   ```
   Email: contractor@test.com
   Password: [your password]
   ```

   - Expected: "Login Successful as Contractor"
   - Redirects to: Contractor Dashboard (/contractor/dashboard)

5. **Test Citizen Login**
   ```
   Email: citizen@test.com
   Password: [your password]
   ```
   - Expected: "Login Successful as Citizen"
   - Redirects to: Citizen Dashboard (/dashboard)

### Step 3: Test Auto-Login (Persistent Session)

1. After successful login, close the app
2. Reopen the app
3. **Expected:**
   - Splash screen appears
   - Automatically redirects to your role's dashboard
   - No need to login again

### Step 4: Test Logout

1. From any dashboard, click logout button
2. **Expected:**
   - Logged out successfully
   - Redirects to Login Screen

## Dashboard Features by Role

### 👤 **Citizen Dashboard** (`/dashboard`)

- Submit complaints
- Track complaints
- Chat with admin
- Profile management

### 🔧 **Contractor Dashboard** (`/contractor/dashboard`)

- View assigned tasks
- Update task status
- Mark tasks as completed
- Chat with admin
- Profile management

### 👨‍💼 **Admin Dashboard** (`/admin/dashboard`)

- View all complaints
- Manage contractors (✅ FULLY FUNCTIONAL)
  - List all contractors
  - Search and filter
  - View contractor details
  - Create new contractors
  - Toggle active/inactive status
  - Change assigned area
- Assign complaints to contractors
- Chat management
- System settings

## Known Working Features

### ✅ **Admin - Contractor Management** (Phase 3 Complete)

1. **List Screen**

   - View all contractors
   - Search by name, email, phone
   - Filter by area
   - See status badges (Active/Inactive)

2. **Detail Screen**

   - View full contractor profile
   - Toggle status (Activate/Deactivate)
   - Change assigned area
   - See performance statistics (placeholder)

3. **Create Screen**
   - Complete form with validation
   - Email format validation
   - BD phone number validation
   - Password strength check
   - Area selection dropdown
   - Success confirmation

## Troubleshooting

### Issue: "Account not found" after successful authentication

**Solution:** Make sure the user document exists in the correct Firestore collection:

- Admin → `admins/{userId}`
- Contractor → `contractors/{userId}`
- Citizen → `citizens/{userId}`

The `userId` must match the Firebase Auth UID.

### Issue: Stuck on splash screen

**Possible causes:**

1. Network connection issues
2. Firestore security rules blocking read access
3. User document doesn't exist

**Debug steps:**

1. Check Flutter console for errors
2. Verify Firestore security rules allow read access
3. Check if user document exists in correct collection

### Issue: Wrong dashboard after login

**Cause:** User document might be in wrong collection

**Solution:** Verify the user document is in the correct collection based on their role.

## Testing Checklist

- [ ] Admin login works and redirects to admin dashboard
- [ ] Contractor login works and redirects to contractor dashboard
- [ ] Citizen login works and redirects to citizen dashboard
- [ ] Invalid credentials show appropriate error
- [ ] Auto-login works after app restart
- [ ] Logout works correctly
- [ ] Admin can view contractor list
- [ ] Admin can create new contractor
- [ ] Admin can view contractor details
- [ ] Admin can toggle contractor status
- [ ] Admin can change contractor area

## Next Steps

After testing the login and contractor management:

1. **Phase 4:** Implement complaint assignment system
2. **Phase 5:** Build contractor task management
3. **Phase 6:** Enhance admin dashboard with analytics
4. **Phase 7:** Update chat system for multi-role support
5. **Phase 8:** Update Firebase security rules

## Firebase Auth Configuration

Ensure Firebase Auth is properly configured:

1. Email/Password provider is enabled in Firebase Console
2. Firestore security rules allow authenticated reads
3. User documents are created with proper structure

## Support

If you encounter any issues:

1. Check Flutter console for detailed errors
2. Verify Firestore data structure matches expected format
3. Ensure Firebase Auth users have corresponding Firestore documents
4. Check network connectivity

---

**Ready to Test!** 🚀

Login with your admin or contractor credentials and explore the contractor management features!
