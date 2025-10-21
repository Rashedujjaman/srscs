# Profile Module - Complete Documentation

## 🎨 Overview

The Profile Module has been completely redesigned with a modern, professional UI that includes profile photo management, personal information display, statistics, and profile editing capabilities.

## ✨ Features Implemented

### 1. **Redesigned Profile Screen** (`profile_screen.dart`)

#### **Modern App Bar with Profile Header**

- **Gradient background** (purple theme)
- **Profile photo display** with circular avatar
- **Camera icon overlay** for updating photo
- **User name and email** display
- **Edit button** in app bar

#### **Statistics Cards**

- **Total Complaints** count
- **Resolved Complaints** count
- **Pending Complaints** count
- Color-coded icons (Orange, Green, Blue)

#### **Personal Information Card**

- NID Number (with badge icon)
- Phone Number (with phone icon)
- Address (with location icon)
- Date of Birth (with cake icon)
- Blood Group (with bloodtype icon)
- Each field has a colored icon background

#### **Quick Actions Section**

- **Chat with Admin** - Links to chat screen
- **View All Complaints** - Links to tracking screen
- **Logout** - With confirmation dialog
- Each action has custom styling and color

#### **Recent Complaints Section**

- Displays last 3 complaints
- Shows complaint type, date, and status
- Color-coded status badges
- "View All" button to see complete list
- Empty state design when no complaints exist

### 2. **Profile Photo Upload**

- Tap camera icon on profile photo
- Select image from gallery
- Automatic upload to Firebase Storage
- Photo URL saved to Firestore
- Loading indicator during upload
- Success/error notifications
- Image optimization (512x512, 75% quality)

### 3. **Edit Profile Screen** (`edit_profile_screen.dart`)

#### **Editable Fields**

- Full Name (text input with validation)
- Phone Number (numeric input with validation)
- Address (multi-line text area)
- Blood Group (dropdown selection: A+, A-, B+, B-, AB+, AB-, O+, O-)
- Date of Birth (date picker with calendar UI)

#### **Non-Editable Information Display**

- NID Number (read-only)
- Email Address (read-only)

#### **Form Validation**

- Full name required
- Phone number required (min 10 digits)
- Address required
- Real-time validation feedback

#### **Save Functionality**

- Updates Firestore database
- Loading state during save
- Success notification
- Error handling with user feedback
- Returns to profile screen on success

## 🎨 Design Highlights

### **Color Scheme**

- Primary: `#9F7AEA` (Purple)
- Secondary: `#7C3AED` (Dark Purple)
- Success: Green
- Warning: Orange
- Error: Red
- Info: Blue

### **UI Components**

- **Cards**: White background with subtle shadows
- **Elevation**: Consistent 10px blur for depth
- **Border Radius**: 12-16px for modern look
- **Icons**: Color-coded and sized appropriately
- **Typography**: Bold headers (18px), Regular text (15px), Small text (12px)

### **Animations**

- Smooth transitions between screens
- Loading indicators for async operations
- Ripple effects on buttons

## 📁 File Structure

```
lib/features/profile/presentation/screens/
├── profile_screen.dart         # Main profile display
└── edit_profile_screen.dart    # Profile editing form
```

## 🔧 Technical Implementation

### **Dependencies Used**

```yaml
- firebase_auth # User authentication
- cloud_firestore # Database
- firebase_storage # Photo storage
- image_picker # Photo selection
- cached_network_image # Efficient image loading
- intl # Date formatting
- get # Navigation
```

### **Firebase Collections**

```
citizens/{userId}
├── fullName: String
├── email: String
├── nid: String
├── phone: String
├── address: String
├── bloodGroup: String
├── dob: Timestamp
├── profilePhotoUrl: String
└── updatedAt: Timestamp
```

### **Firebase Storage Structure**

```
profile_photos/
└── {userId}.jpg
```

## 📱 User Flow

1. **View Profile**

   - User opens profile from dashboard
   - Profile data loads from Firestore
   - Recent complaints load (last 5)
   - Statistics calculate automatically

2. **Update Profile Photo**

   - User taps camera icon
   - Select photo from gallery
   - Photo uploads to Firebase Storage
   - URL saves to Firestore
   - UI updates with new photo

3. **Edit Profile Information**

   - User taps edit icon in app bar
   - Edit screen opens with current data
   - User modifies fields
   - Validation occurs on submit
   - Data saves to Firestore
   - Returns to profile screen

4. **Quick Actions**
   - Chat: Opens admin chat screen
   - View All: Opens complaint tracking
   - Logout: Shows confirmation → Signs out

## 🎯 Key Functions

### **Profile Screen**

```dart
_loadUserData()              // Fetch user from Firestore
_loadComplaints()            // Fetch user complaints
_updateProfilePhoto()        // Upload new photo
_buildStatsCards()           // Display statistics
_buildPersonalInfo()         // Show user details
_buildQuickActions()         // Action buttons
_buildRecentComplaints()     // Recent complaints list
```

### **Edit Profile Screen**

```dart
_selectDate()                // Date picker
_selectBloodGroup()          // Blood group dialog
_saveProfile()               // Save to Firestore
_buildTextField()            // Custom input field
```

## ✅ Validation Rules

- **Full Name**: Required, non-empty
- **Phone**: Required, minimum 10 characters
- **Address**: Required, non-empty
- **Blood Group**: Selected from dropdown
- **Date of Birth**: Selected from calendar
- **NID**: Cannot be edited
- **Email**: Cannot be edited

## 🎨 UI States

### **Loading States**

- Profile data loading: CircularProgressIndicator
- Photo uploading: Modal loading dialog
- Saving profile: Button loading indicator

### **Empty States**

- No complaints: "No complaints yet" with inbox icon

### **Error States**

- Photo upload fail: Red snackbar
- Save fail: Red snackbar with error message

### **Success States**

- Photo uploaded: Green snackbar
- Profile saved: Green snackbar

## 🔐 Security

- User can only view/edit their own profile
- NID and Email are read-only
- Firebase Security Rules should restrict access
- Profile photos stored with user ID as filename

## 📊 Statistics Calculation

```dart
Total Complaints: _recentComplaints.length
Resolved: complaints where status == resolved
Pending: complaints where status == pending
```

## 🚀 Future Enhancements

- [ ] Profile photo cropping before upload
- [ ] Multiple profile photo uploads (gallery)
- [ ] Email verification badge
- [ ] Profile completion percentage
- [ ] Social media links
- [ ] Two-factor authentication
- [ ] Account deletion option
- [ ] Export user data (GDPR compliance)

## 📝 Notes

- Profile photo updates are immediate
- All changes sync to Firestore
- Form validation prevents invalid data
- Timestamps track last update
- Images optimized for performance
- Offline support through Firestore cache

---

**Created:** October 22, 2025  
**Status:** ✅ Complete and Production Ready
