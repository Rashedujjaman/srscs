# Smart Road Safety Complaint System (SRSCS)

A comprehensive Flutter mobile application for reporting and managing road safety complaints with offline support, real-time chat, and admin dashboard.

## 🌟 Features

### 1. **User Authentication & NID Verification**

- Registration with National ID (NID) card verification
- OCR-based NID validation
- Phone/Email login
- Password recovery
- Session management

### 2. **Complaint Submission**

- Submit complaints with 7 categories (Accident, Road Damage, Signal Issues, etc.)
- Multi-media upload (photos, videos, audio recordings)
- GPS location tagging
- Offline form storage with auto-sync
- Draft saving

### 3. **Real-time Live Chat**

- Direct messaging with admin support
- Message status indicators (sent, delivered, read)
- Media sharing in chat
- Timestamp tracking
- Firebase Realtime Database integration

### 4. **Complaint Tracking**

- Real-time status updates (Pending, In Progress, Resolved, Rejected, Closed)
- Filter complaints by status/date
- View complaint history
- Push notifications for status changes
- Timeline view of complaint progress

### 5. **Offline Support & Auto-Sync**

- SQLite local database for offline storage
- Automatic complaint sync when online
- Queue management for pending uploads
- Connectivity monitoring
- Background sync

### 6. **Admin Dashboard**

- View all complaints with statistics
- Filter by status, category, date range
- Assign complaints to departments
- Update complaint status
- Generate reports (CSV/PDF)
- Analytics charts

## 🏗️ Architecture

This project follows **Clean Architecture** principles with three distinct layers:

```
lib/
├── features/
│   ├── auth/
│   │   ├── domain/           # Business logic layer
│   │   │   ├── entities/     # Core business models
│   │   │   ├── repositories/ # Repository interfaces
│   │   │   └── usecases/     # Business use cases
│   │   ├── data/             # Data layer
│   │   │   ├── models/       # Data models (with JSON)
│   │   │   ├── datasources/  # Remote/Local data sources
│   │   │   └── repositories/ # Repository implementations
│   │   └── presentation/     # UI layer
│   │       ├── providers/    # State management
│   │       ├── screens/      # UI screens
│   │       └── widgets/      # Reusable widgets
│   ├── complaint/
│   ├── chat/
│   └── admin/
└── main.dart                 # App entry point with DI
```

### Layer Responsibilities:

- **Domain**: Pure Dart business logic, framework-independent
- **Data**: API calls, database operations, data transformation
- **Presentation**: UI components, state management, user interactions

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Google Maps API key (for location features)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/srscs.git
   cd srscs
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   a. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)

   b. Add Android/iOS apps and download config files:

   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

   c. Enable Firebase services:

   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Realtime Database
   - Firebase Storage

4. **Configure Firestore Collections**

   ```
   /users/{userId}
     - name, email, nidNumber, phone, role

   /complaints/{complaintId}
     - userId, category, description, location, status, mediaUrls
     - createdAt, updatedAt, assignedTo, priority

   /chats/{chatId}/messages/{messageId}
     - senderId, text, mediaUrl, timestamp, read
   ```

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
