# SRSCS - Smart Resident Services & Complaint System# Smart Road Safety Complaint System (SRSCS)

A comprehensive Flutter application for managing citizen services, complaints, and administrative operations with real-time communication features.A comprehensive Flutter mobile application for reporting and managing road safety complaints with offline support, real-time chat, and admin dashboard.

## 📱 Overview## 🌟 Features

SRSCS is a mobile application that connects citizens with administrators for efficient service delivery and complaint management. Built with Flutter and Firebase, it provides a modern, scalable solution for local government and community management.### 1. **User Authentication & NID Verification**

## ✨ Features- Registration with National ID (NID) card verification

- OCR-based NID validation

### User Features- Phone/Email login

- **🔐 Authentication** - Secure login with NID verification- Password recovery

- **👤 Profile Management** - Update personal information and profile photo- Session management

- **📋 Dashboard** - View statistics, latest news, and urgent notices

- **📝 Complaint Management** - Submit and track complaints with offline support### 2. **Complaint Submission**

- **💬 Real-time Chat** - Communicate with administrators with media support

- **🔔 Push Notifications** - Receive instant updates on complaint status and messages- Submit complaints with 7 categories (Accident, Road Damage, Signal Issues, etc.)

- **📊 Complaint Tracking** - View complaint history with status updates- Multi-media upload (photos, videos, audio recordings)

- GPS location tagging

### Admin Features- Offline form storage with auto-sync

- **📊 Admin Dashboard** - Overview of system metrics and pending items- Draft saving

- **💼 Complaint Management** - Review, update, and respond to complaints

- **💬 Chat Management** - Respond to user messages with unread indicators### 3. **Real-time Live Chat**

- **📢 Notice Management** - Create and manage system-wide notices

- **👥 User Management** - View and manage citizen accounts- Direct messaging with admin support

- Message status indicators (sent, delivered, read)

## 🏗️ Architecture- Media sharing in chat

- Timestamp tracking

````- Firebase Realtime Database integration

lib/

├── features/              # Feature modules (Clean Architecture)### 4. **Complaint Tracking**

│   ├── auth/             # Authentication & authorization

│   ├── profile/          # User profile management  - Real-time status updates (Pending, In Progress, Resolved, Rejected, Closed)

│   ├── dashboard/        # Dashboard & news- Filter complaints by status/date

│   ├── complaint/        # Complaint submission & tracking- View complaint history

│   ├── chat/            # Real-time chat functionality- Push notifications for status changes

│   └── admin/           # Admin features- Timeline view of complaint progress

├── services/            # Shared services

│   └── notification_service.dart  # Push notifications### 5. **Offline Support & Auto-Sync**

└── docs/               # Project-wide documentation

```- SQLite local database for offline storage

- Automatic complaint sync when online

Each feature follows **Clean Architecture** principles:- Queue management for pending uploads

- **Data Layer**: Models, data sources (local/remote), repositories- Connectivity monitoring

- **Domain Layer**: Entities, use cases, repository interfaces- Background sync

- **Presentation Layer**: Screens, widgets, providers (state management)

### 6. **Admin Dashboard**

## 🚀 Getting Started

- View all complaints with statistics

### Prerequisites- Filter by status, category, date range

- Flutter SDK (3.24.5 or higher)- Assign complaints to departments

- Dart SDK (3.5.4 or higher)- Update complaint status

- Firebase account- Generate reports (CSV/PDF)

- Android Studio / VS Code- Analytics charts



### Installation## 🏗️ Architecture



1. **Clone the repository**This project follows **Clean Architecture** principles with three distinct layers:

```bash

git clone https://github.com/Rashedujjaman/srscs.git```

cd srscslib/

```├── features/

│   ├── auth/

2. **Install dependencies**│   │   ├── domain/           # Business logic layer

```bash│   │   │   ├── entities/     # Core business models

flutter pub get│   │   │   ├── repositories/ # Repository interfaces

```│   │   │   └── usecases/     # Business use cases

│   │   ├── data/             # Data layer

3. **Configure Firebase**│   │   │   ├── models/       # Data models (with JSON)

```bash│   │   │   ├── datasources/  # Remote/Local data sources

flutterfire configure│   │   │   └── repositories/ # Repository implementations

```│   │   └── presentation/     # UI layer

│   │       ├── providers/    # State management

4. **Set up Firebase Realtime Database**│   │       ├── screens/      # UI screens

│   │       └── widgets/      # Reusable widgets

Edit `lib/main.dart`:│   ├── complaint/

```dart│   ├── chat/

FirebaseDatabase.instance.databaseURL = │   └── admin/

    'https://YOUR-PROJECT-default-rtdb.REGION.firebasedatabase.app/';└── main.dart                 # App entry point with DI

````

5. **Run the app**### Layer Responsibilities:

````bash

flutter run- **Domain**: Pure Dart business logic, framework-independent

```- **Data**: API calls, database operations, data transformation

- **Presentation**: UI components, state management, user interactions

## 📚 Module Documentation

## 🚀 Getting Started

Each feature module has its own README:

### Prerequisites

- **[Chat Module](lib/features/chat/README.md)** - Real-time messaging with media support

- **[Dashboard Module](lib/features/dashboard/README.md)** - Statistics and news display- Flutter SDK (>=3.2.3)

- **[Profile Module](lib/features/profile/README.md)** - User profile management- Dart SDK

- Android Studio / VS Code

## 🛠️ Tech Stack- Firebase account

- Google Maps API key (for location features)

- **Frontend**: Flutter, Dart, Provider (state management), GetX (navigation)

- **Backend**: Firebase (Auth, Firestore, Realtime Database, Storage, Cloud Functions, FCM)### Installation

- **Tools**: FlutterFire, Image Picker, File Picker, Connectivity Plus

1. **Clone the repository**

## 📦 Key Dependencies

   ```bash

```yaml   git clone https://github.com/yourusername/srscs.git

firebase_core: ^2.32.0   cd srscs

firebase_auth: ^4.20.0   ```

cloud_firestore: ^4.17.5

firebase_database: ^10.5.72. **Install dependencies**

firebase_storage: ^11.7.7

firebase_messaging: ^14.9.4   ```bash

provider: ^6.1.2   flutter pub get

get: ^4.6.6   ```

````

3. **Firebase Setup**

## 🧪 Testing

a. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)

````bash

flutter test              # Run unit tests   b. Add Android/iOS apps and download config files:

flutter test --coverage   # Generate coverage

```   - Android: `google-services.json` → `android/app/`

   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

## 📱 Main Screens

   c. Enable Firebase services:

**User**: Login, Dashboard, Profile, Submit Complaint, Tracking, Chat

**Admin**: Dashboard, Complaint Management, Chat Management   - Authentication (Email/Password)

   - Cloud Firestore

## 📄 License   - Firebase Realtime Database

   - Firebase Storage

Proprietary software. All rights reserved.

4. **Configure Firestore Collections**

## 👥 Author

````

**Rashed Ujjaman** - [GitHub](https://github.com/Rashedujjaman) /users/{userId}

     - name, email, nidNumber, phone, role

## 📞 Support

/complaints/{complaintId}

- **Issues**: [GitHub Issues](https://github.com/Rashedujjaman/srscs/issues) - userId, category, description, location, status, mediaUrls

- **Docs**: Check module-specific READMEs - createdAt, updatedAt, assignedTo, priority

--- /chats/{chatId}/messages/{messageId}

     - senderId, text, mediaUrl, timestamp, read

Made with ❤️ using Flutter ```

5. **Android Permissions** (android/app/src/main/AndroidManifest.xml)

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   ```

6. **iOS Permissions** (ios/Runner/Info.plist)

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to capture road safety issues</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>We need photo library access to upload evidence</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to tag complaints</string>
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core

- `flutter_sdk: ">=3.2.3"`
- `provider: ^6.1.5` - State management
- `get: ^4.6.6` - Navigation & routing

### Firebase

- `firebase_core: ^2.32.0`
- `firebase_auth: ^4.20.0`
- `cloud_firestore: ^4.17.5`
- `firebase_database: ^10.5.7`
- `firebase_storage: ^11.7.7`

### Local Storage

- `sqflite: ^2.3.3+1` - SQLite database
- `path_provider: ^2.1.4`

### Media & Location

- `image_picker: ^1.1.2`
- `file_picker: ^6.2.1`
- `video_player: ^2.9.2`
- `audioplayers: ^5.2.1`
- `geolocator: ^10.1.1`
- `permission_handler: ^11.4.0`

### Utilities

- `connectivity_plus: ^5.0.2` - Network monitoring
- `uuid: ^4.5.1` - ID generation
- `dartz: ^0.10.1` - Functional programming
- `intl: ^0.19.0` - Internationalization

### UI

- `cached_network_image: ^3.4.0`
- `syncfusion_flutter_charts: ^27.2.5`

## 🧪 Testing

Run unit tests:

```bash
flutter test
```

Run integration tests:

```bash
flutter test integration_test
```

## 📱 App Navigation

### User Flow

1. Login/Register → NID Verification
2. Dashboard → View Statistics
3. Submit Complaint → Attach Media → GPS Tag → Submit
4. Track Complaints → View Status Updates
5. Live Chat → Message Admin
6. Profile Management

### Admin Flow

1. Admin Login
2. Dashboard → View All Complaints
3. Filter & Search
4. Assign to Department
5. Update Status
6. Generate Reports

## 🔐 Security Features

- Firebase Authentication with secure tokens
- NID verification to prevent spam
- Role-based access control (User/Admin)
- Encrypted local storage
- API key protection

## 🎨 UI Components

- Custom complaint status badges
- Real-time chat bubbles
- Media preview cards
- Filter dialogs
- Loading states & error handling
- Bottom navigation bar

## 🌐 Offline Capabilities

- Local SQLite database stores complaints offline
- Background sync service monitors connectivity
- Automatic upload when network available
- Sync status indicators
- Conflict resolution

## 📊 Admin Analytics

- Total complaints statistics
- Status distribution charts
- Category-wise breakdown
- Response time metrics
- Export to CSV/PDF

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 👥 Team

Smart Road Safety Complaint System Development Team

## 📞 Support

For issues and questions:

- Create a GitHub issue
- Email: support@srscs.gov.bd
- Phone: +880-XXX-XXXXXX

## 🗺️ Roadmap

- [ ] Push notifications implementation
- [ ] Multi-language support (Bengali/English)
- [ ] Dark mode
- [ ] Map view for complaints
- [ ] Public complaint feed
- [ ] Government API integration
- [ ] AI-based complaint categorization
- [ ] Web admin portal

---

**Built with ❤️ using Flutter & Firebase**
