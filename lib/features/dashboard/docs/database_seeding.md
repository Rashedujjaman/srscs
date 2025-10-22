# 🌱 Database Seeding Instructions

## One-Time Setup for Dashboard Data

This guide will help you populate your Firestore database with sample news and notices data.

---

## 📋 What Gets Seeded

### News Items (7 items):

1. ✅ AI-Powered Road Monitoring System (Priority 5 - Highest)
2. ✅ Road Repair Plan 2025 (Priority 4)
3. ✅ Smart Traffic Management (Priority 4)
4. ✅ Road Safety Campaign (Priority 3)
5. ✅ Emergency Hotline Enhanced (Priority 4)
6. ✅ Bridge Construction Updates (Priority 3)
7. ✅ Digital Highway Tolls (Priority 3)

### Notice Items (10 items):

1. 🚨 **Emergency**: Highway accident alert (expires in 6 hours)
2. ⚠️ **Warning**: Severe waterlogging alert (expires in 2 days)
3. 🔧 **Maintenance**: Mirpur road maintenance (5 days)
4. 🔧 **Maintenance**: Pothole repairs (7 days)
5. ℹ️ **Info**: Submit complaints early
6. ℹ️ **Info**: New real-time tracking feature
7. ⚠️ **Warning**: Bridge temporary closure
8. 🔧 **Maintenance**: Traffic signal installation
9. ℹ️ **Info**: Holiday traffic advisory
10. ℹ️ **Info**: Road safety week prizes

---

## 🚀 How to Seed the Database

### Step 1: Uncomment the Seeding Code

Open `lib/main.dart` and find these lines:

```dart
// ⚠️ ONE-TIME SEEDING - UNCOMMENT BELOW, RUN ONCE, THEN COMMENT OUT AGAIN ⚠️
// await seedDashboardData();
```

**Uncomment the seeding line:**

```dart
// ⚠️ ONE-TIME SEEDING - UNCOMMENT BELOW, RUN ONCE, THEN COMMENT OUT AGAIN ⚠️
await seedDashboardData();
```

### Step 2: Run the App

```bash
flutter run
```

The app will:

1. Initialize Firebase
2. Check if data already exists (to prevent duplicates)
3. Seed news and notices if not present
4. Print progress in console
5. Continue to start the app normally

### Step 3: Check Console Output

You should see output like:

```
🌱 Starting database seeding...
📰 Seeding news data...
  ✓ Added news: New AI-Powered Road Monitoring System Launched
  ✓ Added news: Road Repair and Maintenance Plan 2025 Announced
  ... (more items)
✅ News data seeded successfully! (7 items)
📢 Seeding notices data...
  ✓ Added notice: Emergency: Dhaka-Chittagong Highway Accident
  ✓ Added notice: Severe Waterlogging Alert - Heavy Rainfall Expected
  ... (more items)
✅ Notices data seeded successfully! (10 items)
✅ Database seeding completed successfully!
📝 Remember to comment out the seedDashboardData() call in main.dart
```

### Step 4: Comment Out the Seeding Code Again

**Important!** After successful seeding, comment out the line again:

```dart
// ⚠️ ONE-TIME SEEDING - UNCOMMENT BELOW, RUN ONCE, THEN COMMENT OUT AGAIN ⚠️
// await seedDashboardData();
```

This prevents re-seeding on every app restart.

---

## ✅ Verify Seeded Data

### In Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database**
4. Check for these collections:
   - `news` - should have 7 documents
   - `notices` - should have 10 documents

### In Your App:

1. Login to the app
2. Go to Dashboard
3. You should see:
   - Latest news items in the News section
   - Active notices in the Notices section
   - Urgent notices at the top (if any are critical/high priority)

---

## 🔄 Re-seeding (Optional)

If you want to clear and re-seed the data:

### Option 1: Manual Deletion

1. Go to Firebase Console
2. Delete `news` and `notices` collections
3. Uncomment seeding code and run again

### Option 2: Use Clear Function

In `seed_dashboard_data.dart`, there's a `clearDashboardData()` function.

Add this to your main temporarily:

```dart
await clearDashboardData(); // Clear old data
await seedDashboardData();  // Seed fresh data
```

---

## 📝 Customizing Seed Data

To customize the seeded data, edit `lib/features/dashboard/data/datasources/seed_dashboard_data.dart`:

### Add More News:

Find the `newsData` list in `_seedNewsData()` and add new items:

```dart
{
  'title': 'Your News Title',
  'content': 'Your detailed content...',
  'publishedAt': Timestamp.now(),
  'source': 'Your Source Name',
  'externalLink': 'https://example.com', // optional
  'priority': 4, // 1-5
}
```

### Add More Notices:

Find the `noticesData` list in `_seedNoticesData()` and add new items:

```dart
{
  'title': 'Your Notice Title',
  'message': 'Your notice message...',
  'type': 'warning', // emergency, warning, info, maintenance
  'createdAt': Timestamp.now(),
  'expiresAt': Timestamp.fromDate(futureDate), // optional
  'isActive': true,
  'affectedAreas': ['Dhaka', 'Chittagong'], // optional
}
```

---

## 🛡️ Safety Features

The seeding function includes safety checks:

✅ **Duplicate Prevention**: Checks if data exists before seeding  
✅ **Error Handling**: Catches and reports any errors  
✅ **Console Logging**: Clear progress indicators  
✅ **Skip Logic**: Won't overwrite existing data

---

## ⚠️ Important Notes

1. **Run Only Once**: The seeding code should only run once to populate initial data
2. **Comment Out After**: Always comment out the seeding call after running
3. **Check Firebase**: Verify data in Firebase Console after seeding
4. **Network Required**: App needs internet connection for seeding to work
5. **Firebase Initialized**: Ensure Firebase is properly configured

---

## 🐛 Troubleshooting

### Issue: "Data already exists" message

**Solution**: This is normal! It prevents duplicate seeding. If you want to re-seed, delete collections first.

### Issue: No console output

**Solution**: Check your terminal/console. May need to restart app completely.

### Issue: Firebase permission denied

**Solution**: Check Firestore security rules. Ensure authenticated users can write to `news` and `notices` collections (or allow during development):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /news/{newsId} {
      allow read: if true;
      allow write: if true; // Change to admin-only in production
    }
    match /notices/{noticeId} {
      allow read: if true;
      allow write: if true; // Change to admin-only in production
    }
  }
}
```

### Issue: App crashes on startup

**Solution**: Make sure you commented out the seeding call after first successful run.

---

## 📊 Expected Results

After seeding, your dashboard should show:

- **7 news items** from various government sources
- **10 notices** with different types and urgency levels
- **Urgent notices section** showing emergency/warning items
- **"NEW" badges** on recent news items
- **Notification badge** with unread notice count

---

## 🎉 Success!

Once seeding is complete and you've commented out the code, your app is ready with realistic sample data for testing and demonstration!

Need to add more data later? Just edit `seed_dashboard_data.dart` and repeat the process.

---

**File Location**: `lib/features/dashboard/data/datasources/seed_dashboard_data.dart`

**Usage in main.dart**: `await seedDashboardData();` (comment out after use)
