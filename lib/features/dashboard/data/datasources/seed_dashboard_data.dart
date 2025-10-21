import 'package:cloud_firestore/cloud_firestore.dart';

/// ONE-TIME DATABASE SEEDER
///
/// This file contains functions to seed the database with sample news and notices.
/// Call `seedDashboardData()` once from main.dart, then comment it out.
///
/// Usage in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///
///   // ONE-TIME SEEDING - COMMENT OUT AFTER FIRST RUN
///   await seedDashboardData();
///
///   runApp(const MyApp());
/// }
/// ```

Future<void> seedDashboardData() async {
  print('🌱 Starting database seeding...');

  final firestore = FirebaseFirestore.instance;

  try {
    // Check if data already exists to prevent duplicate seeding
    final newsCount = await firestore.collection('news').limit(1).get();
    if (newsCount.docs.isNotEmpty) {
      print('⚠️ News data already exists. Skipping news seeding...');
    } else {
      await _seedNewsData(firestore);
    }

    final noticesCount = await firestore.collection('notices').limit(1).get();
    if (noticesCount.docs.isNotEmpty) {
      print('⚠️ Notices data already exists. Skipping notices seeding...');
    } else {
      await _seedNoticesData(firestore);
    }

    print('✅ Database seeding completed successfully!');
    print(
        '📝 Remember to comment out the seedDashboardData() call in main.dart');
  } catch (e) {
    print('❌ Error seeding database: $e');
  }
}

/// Seed news data
Future<void> _seedNewsData(FirebaseFirestore firestore) async {
  print('📰 Seeding news data...');

  final newsData = [
    {
      'title': 'New AI-Powered Road Monitoring System Launched',
      'content':
          '''The Government of Bangladesh has officially launched an advanced AI-powered road monitoring system to detect and report road safety issues in real-time. This system uses machine learning algorithms to identify potholes, damaged signs, and other hazards.

Key Features:
- 24/7 automated monitoring
- Real-time hazard detection
- Predictive maintenance scheduling
- Integration with citizen complaint system

The system is expected to reduce response time by 40% and improve road safety across major highways and urban areas.''',
      'publishedAt': Timestamp.now(),
      'source': 'Roads and Highways Department (RHD)',
      'externalLink': 'https://rhd.gov.bd',
      'priority': 5,
    },
    {
      'title': 'Road Repair and Maintenance Plan 2025 Announced',
      'content':
          '''The Ministry of Transport has unveiled its comprehensive road repair and maintenance plan for 2025, allocating significant resources to improve road infrastructure nationwide.

Budget Allocation:
- Major highway repairs: 5000 Crore BDT
- Urban road maintenance: 2000 Crore BDT
- Rural road development: 1500 Crore BDT

Target Areas:
- Dhaka-Chittagong Highway
- Dhaka-Sylhet Highway
- Cox's Bazar coastal road
- Various urban arterial roads

Citizens can track progress through the SRSCS mobile app and report any issues encountered.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      'source': 'Ministry of Transport',
      'priority': 4,
    },
    {
      'title': 'Smart Traffic Management System Implementation',
      'content':
          '''To reduce traffic congestion and improve road safety, the government is implementing smart traffic management systems in major cities.

New Features:
- AI-powered traffic signal optimization
- Real-time traffic monitoring
- Incident detection and response
- Mobile app integration for citizens

The first phase will cover Dhaka, Chittagong, and Sylhet metropolitan areas, with expansion planned for other cities by 2026.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 5)),
      ),
      'source': 'Bangladesh Road Transport Authority (BRTA)',
      'priority': 4,
    },
    {
      'title': 'Road Safety Awareness Campaign 2025',
      'content':
          '''The government has launched a nationwide road safety awareness campaign focusing on responsible driving and pedestrian safety.

Campaign Highlights:
- Free driver training workshops
- School safety education programs
- Community awareness sessions
- Social media campaigns

Citizens are encouraged to participate and spread awareness about road safety in their communities.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)),
      ),
      'source': 'Road Safety Foundation',
      'priority': 3,
    },
    {
      'title': 'Emergency Response Hotline Enhanced',
      'content':
          '''The national emergency response hotline for road incidents has been upgraded with new features and faster response capabilities.

Improvements:
- GPS location tracking
- Multi-language support
- Video call capability
- Integration with SRSCS app

Dial 999 for immediate assistance in case of road emergencies or accidents.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 10)),
      ),
      'source': 'Emergency Services',
      'externalLink': 'https://999.gov.bd',
      'priority': 4,
    },
    {
      'title': 'Bridge Construction Updates - Major Projects',
      'content':
          '''Several major bridge construction projects are underway to improve connectivity and reduce travel time across the country.

Ongoing Projects:
- Padma Bridge 2nd Phase
- Karnaphuli Tunnel expansion
- Rural bridge development program

These projects will significantly improve transportation infrastructure and boost economic growth in rural areas.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 15)),
      ),
      'source': 'Bangladesh Bridge Authority',
      'priority': 3,
    },
    {
      'title': 'Digital Payment System for Highway Tolls',
      'content':
          '''A new digital payment system for highway tolls is being rolled out to reduce waiting times and improve efficiency.

Benefits:
- Cashless transactions
- Reduced waiting time
- Electronic toll collection (ETC)
- Mobile app integration

Motorists can register online and link their payment methods for seamless travel experience.''',
      'publishedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 20)),
      ),
      'source': 'Roads and Highways Department (RHD)',
      'priority': 3,
    },
  ];

  for (var news in newsData) {
    await firestore.collection('news').add(news);
    print('  ✓ Added news: ${news['title']}');
  }

  print('✅ News data seeded successfully! (${newsData.length} items)');
}

/// Seed notices data
Future<void> _seedNoticesData(FirebaseFirestore firestore) async {
  print('📢 Seeding notices data...');

  final noticesData = [
    {
      'title': 'Emergency: Dhaka-Chittagong Highway Accident',
      'message':
          'A major accident has occurred on Dhaka-Chittagong Highway near Comilla. Traffic is diverted via alternative routes. Please avoid the area until further notice. Emergency services are on site.',
      'type': 'emergency',
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 6)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Chittagong', 'Comilla'],
    },
    {
      'title': 'Severe Waterlogging Alert - Heavy Rainfall Expected',
      'message':
          'The Meteorological Department has issued a severe weather warning. Heavy to very heavy rainfall is expected in the next 24-48 hours. Low-lying areas may experience waterlogging. Citizens are advised to avoid unnecessary travel and report any road flooding through the SRSCS app.',
      'type': 'warning',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 2)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Sylhet', 'Mymensingh', 'Chittagong'],
    },
    {
      'title': 'Road Maintenance - Mirpur Section 10',
      'message':
          'Scheduled road maintenance work will be conducted on Mirpur Section 10 main road from 10:00 PM to 6:00 AM daily for the next 5 days. Traffic may experience delays. Alternative routes are available via Mirpur-1 and Mirpur-14.',
      'type': 'maintenance',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 5)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 5)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Mirpur'],
    },
    {
      'title': 'Pothole Repair Initiative - Multiple Locations',
      'message':
          'The Roads and Highways Department is conducting urgent pothole repair work in multiple locations across major cities. Work is scheduled during off-peak hours to minimize traffic disruption. Thank you for your patience and cooperation.',
      'type': 'maintenance',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi'],
    },
    {
      'title': 'Submit Complaints Early to Avoid Delays',
      'message':
          'Due to high volume of complaints during monsoon season, we encourage citizens to submit road safety complaints as early as possible. Include photos and exact location for faster processing. Average response time is currently 48-72 hours.',
      'type': 'info',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      'isActive': true,
    },
    {
      'title': 'New Feature: Real-time Complaint Tracking',
      'message':
          'We are excited to announce a new feature in the SRSCS app! You can now track your complaints in real-time and receive instant notifications when the status changes. Update your app to the latest version to access this feature.',
      'type': 'info',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 3)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      ),
      'isActive': true,
    },
    {
      'title': 'Bridge Construction - Temporary Closure',
      'message':
          'The bridge on the Dhaka-Aricha Highway near Savar will be temporarily closed for inspection and minor repairs on Friday, October 25, 2025, from 1:00 AM to 5:00 AM. Please plan your travel accordingly.',
      'type': 'warning',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Savar', 'Manikganj'],
    },
    {
      'title': 'Traffic Signal Installation - Uttara Sector 11',
      'message':
          'New traffic signals are being installed at major intersections in Uttara Sector 11. Installation work is in progress and may cause temporary traffic delays. The project is expected to complete by end of this week.',
      'type': 'maintenance',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 4)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      ),
      'isActive': true,
      'affectedAreas': ['Dhaka', 'Uttara'],
    },
    {
      'title': 'Holiday Traffic Advisory - Eid-ul-Fitr',
      'message':
          'With Eid-ul-Fitr approaching, heavy traffic is expected on major highways. Plan your travel in advance, avoid peak hours, and check real-time traffic updates in the app. Safe travels!',
      'type': 'info',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 5)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 10)),
      ),
      'isActive': true,
    },
    {
      'title': 'Road Safety Week - Participate and Win Prizes',
      'message':
          'Road Safety Week is here! Participate in our awareness campaign, share road safety tips on social media with #SafeRoadsBD, and stand a chance to win exciting prizes. Top contributors will be recognized by the ministry.',
      'type': 'info',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 6)),
      ),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'isActive': true,
    },
  ];

  for (var notice in noticesData) {
    await firestore.collection('notices').add(notice);
    print('  ✓ Added notice: ${notice['title']}');
  }

  print('✅ Notices data seeded successfully! (${noticesData.length} items)');
}

/// Optional: Clear all seeded data (use with caution!)
Future<void> clearDashboardData() async {
  print('⚠️ WARNING: Clearing all dashboard data...');

  final firestore = FirebaseFirestore.instance;

  try {
    // Delete all news
    final newsSnapshot = await firestore.collection('news').get();
    for (var doc in newsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✓ Cleared ${newsSnapshot.docs.length} news items');

    // Delete all notices
    final noticesSnapshot = await firestore.collection('notices').get();
    for (var doc in noticesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✓ Cleared ${noticesSnapshot.docs.length} notices');

    print('✅ Dashboard data cleared successfully!');
  } catch (e) {
    print('❌ Error clearing data: $e');
  }
}
