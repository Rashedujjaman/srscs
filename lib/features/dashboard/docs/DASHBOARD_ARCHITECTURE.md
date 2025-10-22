# Dashboard Module - Clean Architecture Implementation

## Overview

The Dashboard module has been completely refactored following Clean Architecture principles to provide citizens with a comprehensive, intelligent, and responsive overview of their complaint system interactions, latest news, and important notices.

## 🏗️ Architecture Layers

### 1. Domain Layer (`lib/features/dashboard/domain/`)

#### Entities

**`dashboard_statistics.dart`**: Core statistics entity for citizen's complaint metrics

- **Properties**:

  - `totalComplaints`: Total number of complaints submitted
  - `pendingComplaints`: Complaints awaiting review
  - `underReviewComplaints`: Complaints being reviewed
  - `inProgressComplaints`: Complaints being worked on
  - `resolvedComplaints`: Successfully resolved complaints
  - `rejectedComplaints`: Rejected complaints
  - `averageResponseTime`: Average time to resolution (hours)
  - `complaintsByCategory`: Distribution across complaint types
  - `recentComplaintIds`: IDs of 5 most recent complaints

- **Computed Properties**:
  - `resolutionRate`: Percentage of resolved complaints
  - `activeRate`: Percentage of active complaints
  - `mostFrequentCategory`: Most common complaint type

**`news_item.dart`**: News and announcements from government authorities

- **Properties**:

  - `id`, `title`, `content`
  - `thumbnailUrl`: Optional news image
  - `publishedAt`: Publication timestamp
  - `source`: e.g., "RHD", "Ministry of Transport"
  - `externalLink`: Optional link for more details
  - `priority`: 1-5 (higher = more important)

- **Computed Properties**:
  - `isRecent`: Published within last 7 days
  - `timeAgo`: Human-readable relative time

**`notice_item.dart`**: Important notices and alerts for citizens

- **Properties**:

  - `id`, `title`, `message`
  - `type`: Emergency, Warning, Info, Maintenance
  - `createdAt`, `expiresAt`
  - `isActive`: Whether notice is still active
  - `affectedAreas`: Optional list of affected locations

- **Computed Properties**:

  - `isValid`: Check if notice hasn't expired
  - `urgency`: Critical, High, Medium, Low

- **Enums**:
  - `NoticeType`: emergency, warning, info, maintenance
  - `NoticeUrgency`: critical, high, medium, low

#### Repository Interface

**`dashboard_repository.dart`**: Abstract contract for dashboard operations

```dart
- getDashboardStatistics(String userId): Future<DashboardStatistics>
- getLatestNews({int limit}): Future<List<NewsItem>>
- getActiveNotices({bool includeExpired}): Future<List<NoticeItem>>
- getNoticeById(String noticeId): Future<NoticeItem>
- markNoticeAsRead(String userId, String noticeId): Future<void>
- getUnreadNoticeCount(String userId): Future<int>
```

#### Use Cases

1. **`get_dashboard_statistics.dart`**: Fetch user's complaint statistics
2. **`get_latest_news.dart`**: Retrieve latest news items with limit
3. **`get_active_notices.dart`**: Fetch active notices (optionally include expired)
4. **`get_unread_notice_count.dart`**: Get count of unread notices for notification badge

### 2. Data Layer (`lib/features/dashboard/data/`)

#### Models

**`dashboard_statistics_model.dart`**: Extends DashboardStatistics entity

- `fromFirestore(DocumentSnapshot)`: Parse from Firestore document
- `toFirestore()`: Convert to Firestore map
- `fromEntity(DashboardStatistics)`: Convert from domain entity

**`news_item_model.dart`**: Extends NewsItem entity

- Handles Timestamp ↔ DateTime conversion
- Serialization for Firestore storage

**`notice_item_model.dart`**: Extends NoticeItem entity

- Parses NoticeType enum from string
- Handles optional expiry dates and affected areas

#### Data Source

**`dashboard_remote_data_source.dart`**: Firebase Firestore operations

**Statistics Calculation** (Intelligent Algorithm):

```dart
// Fetches all user complaints and calculates:
1. Status distribution (pending, under review, in progress, resolved, rejected)
2. Category-wise breakdown
3. Average response time (for resolved complaints)
4. Recent complaint IDs (last 5, sorted by creation date)
```

**News Retrieval**:

```dart
// Fetches from 'news' collection:
- Orders by publishedAt (descending)
- Limits to specified count
- Returns most recent news first
```

**Notices Management**:

```dart
// Fetches from 'notices' collection:
- Filters by isActive flag
- Validates expiry dates
- Tracks read/unread status per user
- Stores read receipts in 'users/{userId}/readNotices' subcollection
```

#### Repository Implementation

**`dashboard_repository_impl.dart`**: Implements DashboardRepository

- Delegates all operations to DashboardRemoteDataSource
- Acts as intermediary between domain and data layers

### 3. Presentation Layer (`lib/features/dashboard/presentation/`)

#### Provider

**`dashboard_provider.dart`**: State management with ChangeNotifier

**State Variables**:

```dart
- _statistics: DashboardStatistics?
- _newsList: List<NewsItem>
- _noticesList: List<NoticeItem>
- _unreadNoticeCount: int
- _isLoadingStatistics, _isLoadingNews, _isLoadingNotices: bool
- _error: String?
```

**Public Methods**:

```dart
- loadDashboardData(): Load all dashboard data in parallel
- loadStatistics(): Load user statistics
- loadNews({int limit}): Load latest news
- loadNotices({bool includeExpired}): Load active notices
- loadUnreadNoticeCount(): Load unread notice count
- refreshDashboard(): Refresh all data
- clearError(): Clear error state
```

**Computed Properties**:

```dart
- urgentNotices: Filters notices by critical/high urgency
- recentNews: Filters news published within last 7 days
- isLoading: Any loading operation in progress
```

#### Widgets

**`statistics_card.dart`**: Displays user complaint statistics

- **Features**:
  - Total, Resolved, Pending complaint counts with icons
  - Resolution rate progress bar
  - Average response time display
  - Color-coded stat items (blue, green, orange)
  - Responsive layout with rounded corners

**`news_card.dart`**: Displays individual news item

- **Features**:
  - Priority-based color coding
  - "NEW" badge for recent news
  - Source and time ago display
  - Thumbnail/icon support
  - Tap to view details

**`notice_card.dart`**: Displays individual notice

- **Features**:
  - Type-based styling (emergency: red, warning: orange, etc.)
  - Urgency badges (CRITICAL, URGENT, IMPORTANT)
  - Icon indicators per notice type
  - Affected areas chips display
  - Border and background colors by type

#### Screen

**`dashboard_screen.dart`**: Main dashboard UI

**Features**:

1. **Smart App Bar**:

   - Profile avatar with photo (taps to profile screen)
   - SRSCS logo/title
   - Notification bell with unread count badge
   - Consumer widgets for reactive updates

2. **Personalized Greeting**:

   - "Hello, [FirstName]!" with user's actual name
   - Subtitle: "Welcome to Smart Road Safety Complaint System"

3. **Statistics Overview**:

   - StatisticsCard showing all metrics
   - Visual progress indicators
   - Loading state while fetching

4. **Urgent Notices Section** (Conditional):

   - Only shown if critical/high urgency notices exist
   - Red alert styling
   - Unread count badge
   - Quick access to urgent information

5. **Latest News Section**:

   - Displays top 3 news items
   - "View All" button to see complete list
   - Empty state if no news
   - Loading indicator during fetch

6. **All Notices Section**:

   - Displays top 3 notices
   - "View All" button for complete list
   - Empty state if no notices
   - Type and urgency filtering

7. **Pull-to-Refresh**:

   - RefreshIndicator wrapping entire content
   - Reloads all dashboard data

8. **Floating Action Button**:

   - "Submit Complaint" - navigates to complaint submission

9. **Bottom Navigation Bar**:
   - Dashboard (current)
   - Track (complaint tracking)
   - Chat (admin support)
   - Profile

**Modal Views**:

- **News Details Modal**: Bottom sheet with full news content, source, time, external link
- **Notice Details Dialog**: Alert dialog with full notice message, affected areas
- **All News Screen**: Full-screen list of all news items
- **All Notices Screen**: Full-screen list of all notices

## 🎯 Key Features & Intelligence

### 1. **Real-time Statistics Calculation**

- Dynamically calculates stats from user's complaints in Firestore
- No pre-computed statistics needed
- Always up-to-date with latest complaint status changes

### 2. **Smart Notice Management**

- Urgency-based prioritization (critical notices shown first)
- Expiry date validation
- Read/unread tracking per user
- Area-specific notices with location filters

### 3. **Priority-based News Display**

- High-priority news shown prominently
- Recent news flagged with "NEW" badge
- Source attribution for credibility

### 4. **Intelligent Loading States**

- Parallel data loading for faster initial load
- Individual loading states per section
- Graceful error handling with retry option
- Skeleton/placeholder during load

### 5. **Responsive & User-Friendly**

- Pull-to-refresh for manual updates
- Empty states with helpful messages
- Color-coded visual hierarchy
- Smooth navigation and transitions

## 📊 Firestore Schema

### Collections

**`complaints`** (existing):

```
/complaints/{complaintId}
  - userId: string
  - type: string (pothole, brokenSign, etc.)
  - status: string (pending, underReview, inProgress, resolved, rejected)
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - description, mediaUrls, location, etc.
```

**`news`** (new):

```
/news/{newsId}
  - title: string
  - content: string
  - thumbnailUrl: string (optional)
  - publishedAt: Timestamp
  - source: string (e.g., "RHD")
  - externalLink: string (optional)
  - priority: number (1-5)
```

**`notices`** (new):

```
/notices/{noticeId}
  - title: string
  - message: string
  - type: string (emergency, warning, info, maintenance)
  - createdAt: Timestamp
  - expiresAt: Timestamp (optional)
  - isActive: boolean
  - affectedAreas: array of strings (optional)
```

**`users/{userId}/readNotices`** (new):

```
/users/{userId}/readNotices/{noticeId}
  - readAt: Timestamp
```

## 🔄 Data Flow

1. **User opens dashboard** → `DashboardScreen.initState()`
2. **Load data in parallel**:
   - `loadDashboardData()` → calls all use cases
   - `loadProfile()` → gets user profile
3. **Provider notifies listeners** → UI updates automatically
4. **Consumer widgets rebuild** → display fresh data

## 🎨 Design Highlights

### Color Scheme

- Primary: `#9F7AEA` (Purple) - Brand color
- Background: `#FDF4FF` (Light lavender)
- Success: Green (resolved complaints)
- Warning: Orange (pending complaints)
- Error: Red (rejected, critical notices)

### Typography

- Headlines: 22-24px, Bold
- Subheadings: 18px, Semi-bold
- Body: 14-16px, Regular
- Captions: 12px, Regular

### Spacing & Layout

- Consistent 16px padding
- 12-24px spacing between sections
- Rounded corners (12-16px radius)
- Card elevation for depth

## 🚀 Performance Optimizations

1. **Parallel Data Loading**: All dashboard data loads simultaneously
2. **Lazy Loading**: News and notices limited to top 3, load more on demand
3. **Consumer Widgets**: Only rebuild affected UI portions
4. **Efficient Queries**: Firestore queries with proper indexing
5. **Error Boundaries**: Graceful degradation if one section fails

## 🧪 Testing Recommendations

### Unit Tests

- Test entity computed properties (resolutionRate, isRecent, urgency)
- Test use cases with mocked repository
- Test provider state management logic

### Widget Tests

- Test StatisticsCard rendering with different data
- Test NewsCard and NoticeCard variations
- Test empty and loading states

### Integration Tests

- Test complete dashboard flow
- Test pull-to-refresh functionality
- Test navigation to detail views

## 📱 Citizen-Focused Design

This dashboard is specifically designed for **citizens** (not admins):

### What Citizens See:

✅ Their own complaint statistics
✅ Government news and updates
✅ Public notices and alerts
✅ Quick access to submit new complaints
✅ Navigation to track existing complaints

### What Citizens Don't See:

❌ All users' complaints (privacy)
❌ Admin controls or actions
❌ System-wide statistics
❌ Other citizens' data

### Mobile-First Approach:

- Optimized for portrait phone screens
- Touch-friendly tap targets
- Swipe gestures (pull-to-refresh, modal dismiss)
- Responsive layouts for different screen sizes

## 🔐 Security & Privacy

1. **Data Isolation**: Users only see their own statistics
2. **Firestore Rules**: Server-side validation (to be configured)
3. **Read Receipts**: Notice read tracking isolated per user
4. **No Sensitive Data**: Dashboard shows aggregated, safe information

## 🎯 Future Enhancements

1. **Analytics Charts**: Visual graphs for complaint trends
2. **Notifications**: Push notifications for urgent notices
3. **Filters**: Filter news/notices by category
4. **Search**: Search through news and notices
5. **Bookmarks**: Save important news/notices
6. **Sharing**: Share news items via social media
7. **Multilingual**: Support for Bengali language
8. **Offline Mode**: Cache dashboard data locally

## 📄 Files Structure

```
lib/features/dashboard/
├── domain/
│   ├── entities/
│   │   ├── dashboard_statistics.dart (45 lines)
│   │   ├── news_item.dart (52 lines)
│   │   └── notice_item.dart (64 lines)
│   ├── repositories/
│   │   └── dashboard_repository.dart (24 lines)
│   └── usecases/
│       ├── get_dashboard_statistics.dart (11 lines)
│       ├── get_latest_news.dart (11 lines)
│       ├── get_active_notices.dart (11 lines)
│       └── get_unread_notice_count.dart (11 lines)
├── data/
│   ├── models/
│   │   ├── dashboard_statistics_model.dart (65 lines)
│   │   ├── news_item_model.dart (54 lines)
│   │   └── notice_item_model.dart (78 lines)
│   ├── datasources/
│   │   └── dashboard_remote_data_source.dart (220 lines)
│   └── repositories/
│       └── dashboard_repository_impl.dart (40 lines)
└── presentation/
    ├── providers/
    │   └── dashboard_provider.dart (165 lines)
    ├── widgets/
    │   ├── statistics_card.dart (143 lines)
    │   ├── news_card.dart (130 lines)
    │   └── notice_card.dart (195 lines)
    └── screens/
        └── dashboard_screen.dart (550 lines)
```

**Total Lines**: ~1,877 lines of clean, well-documented code

## 🎓 Clean Architecture Benefits

1. **Separation of Concerns**: Business logic, data access, and UI are completely separated
2. **Testability**: Each layer can be tested independently with mocks
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features (e.g., new notice types, analytics)
5. **Reusability**: Entities and use cases can be reused in web admin panel
6. **Framework Independence**: Domain layer has no Flutter dependencies

## 🌟 Highlights of Intelligence

### Smart Defaults

- Shows recent news first
- Prioritizes urgent notices
- Calculates statistics on-demand

### User Experience

- Personalized greetings
- Contextual empty states
- Smooth loading transitions
- Pull-to-refresh for control

### Visual Hierarchy

- Color-coded importance
- Urgency badges
- Progressive disclosure (top 3, then view all)

### Data Efficiency

- Parallel loading
- Lazy pagination
- Minimal re-renders

---

**Built with ❤️ for Citizens | Following Clean Architecture Principles**
