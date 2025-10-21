import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_statistics_model.dart';
import '../models/news_item_model.dart';
import '../models/notice_item_model.dart';

class DashboardRemoteDataSource {
  final FirebaseFirestore firestore;

  DashboardRemoteDataSource({required this.firestore});

  /// Fetch dashboard statistics by calculating from user's complaints
  Future<DashboardStatisticsModel> getDashboardStatistics(String userId) async {
    try {
      final complaintsQuery = await firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      final complaints = complaintsQuery.docs;

      int totalComplaints = complaints.length;
      int pending = 0;
      int underReview = 0;
      int inProgress = 0;
      int resolved = 0;
      int rejected = 0;

      Map<String, int> categoryCount = {};
      List<String> recentIds = [];
      double totalResponseTime = 0;
      int resolvedWithResponseTime = 0;

      // Sort by creation date and get recent IDs
      final sortedComplaints = complaints.toList()
        ..sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp).toDate();
          final bTime = (b.data()['createdAt'] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });

      recentIds = sortedComplaints.take(5).map((doc) => doc.id).toList();

      for (var doc in complaints) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final category = data['type'] ?? 'other';

        // Count by status
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'underReview':
            underReview++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            // Calculate response time
            if (data['createdAt'] != null && data['updatedAt'] != null) {
              final created = (data['createdAt'] as Timestamp).toDate();
              final updated = (data['updatedAt'] as Timestamp).toDate();
              final hours = updated.difference(created).inHours.toDouble();
              totalResponseTime += hours;
              resolvedWithResponseTime++;
            }
            break;
          case 'rejected':
            rejected++;
            break;
        }

        // Count by category
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      final averageResponseTime = resolvedWithResponseTime > 0
          ? totalResponseTime / resolvedWithResponseTime
          : 0.0;

      return DashboardStatisticsModel(
        totalComplaints: totalComplaints,
        pendingComplaints: pending,
        underReviewComplaints: underReview,
        inProgressComplaints: inProgress,
        resolvedComplaints: resolved,
        rejectedComplaints: rejected,
        averageResponseTime: averageResponseTime,
        complaintsByCategory: categoryCount,
        recentComplaintIds: recentIds,
      );
    } catch (e) {
      print('Error fetching dashboard statistics: $e');
      rethrow;
    }
  }

  /// Fetch latest news items
  Future<List<NewsItemModel>> getLatestNews({int limit = 10}) async {
    try {
      final newsQuery = await firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return newsQuery.docs
          .map((doc) => NewsItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch active notices
  Future<List<NoticeItemModel>> getActiveNotices(
      {bool includeExpired = false}) async {
    try {
      Query query = firestore.collection('notices');

      if (!includeExpired) {
        query = query.where('isActive', isEqualTo: true);
      }

      final noticesQuery =
          await query.orderBy('createdAt', descending: true).get();

      final notices = noticesQuery.docs
          .map((doc) => NoticeItemModel.fromFirestore(doc))
          .toList();

      // Filter expired notices if not including them
      if (!includeExpired) {
        return notices.where((notice) => notice.isValid).toList();
      }

      return notices;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch specific notice by ID
  Future<NoticeItemModel> getNoticeById(String noticeId) async {
    try {
      final doc = await firestore.collection('notices').doc(noticeId).get();

      if (!doc.exists) {
        throw Exception('Notice not found');
      }

      return NoticeItemModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notice as read by user
  Future<void> markNoticeAsRead(String userId, String noticeId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('readNotices')
          .doc(noticeId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread notice count for user
  Future<int> getUnreadNoticeCount(String userId) async {
    try {
      // Get all active notices
      final activeNotices = await getActiveNotices(includeExpired: false);

      // Get read notices for user
      final readNoticesQuery = await firestore
          .collection('users')
          .doc(userId)
          .collection('readNotices')
          .get();

      final readNoticeIds = readNoticesQuery.docs.map((doc) => doc.id).toSet();

      // Count unread
      final unreadCount = activeNotices
          .where((notice) => !readNoticeIds.contains(notice.id))
          .length;

      return unreadCount;
    } catch (e) {
      return 0;
    }
  }
}
