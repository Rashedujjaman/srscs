import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/dashboard_statistics.dart';
import '../../domain/entities/news_item.dart';
import '../../domain/entities/notice_item.dart';
import '../../domain/usecases/get_dashboard_statistics.dart';
import '../../domain/usecases/get_latest_news.dart';
import '../../domain/usecases/get_active_notices.dart';
import '../../domain/usecases/get_unread_notice_count.dart';
import '../../domain/usecases/mark_notice_as_read.dart';

class DashboardProvider with ChangeNotifier {
  final GetDashboardStatistics getDashboardStatisticsUseCase;
  final GetLatestNews getLatestNewsUseCase;
  final GetActiveNotices getActiveNoticesUseCase;
  final GetUnreadNoticeCount getUnreadNoticeCountUseCase;
  final MarkNoticeAsRead markNoticeAsReadUseCase;
  final FirebaseAuth firebaseAuth;

  DashboardProvider({
    required this.getDashboardStatisticsUseCase,
    required this.getLatestNewsUseCase,
    required this.getActiveNoticesUseCase,
    required this.getUnreadNoticeCountUseCase,
    required this.markNoticeAsReadUseCase,
    required this.firebaseAuth,
  });

  // State variables
  DashboardStatistics? _statistics;
  List<NewsItem> _newsList = [];
  List<NoticeItem> _noticesList = [];
  int _unreadNoticeCount = 0;

  bool _isLoadingStatistics = false;
  bool _isLoadingNews = false;
  bool _isLoadingNotices = false;

  String? _error;

  // Getters
  DashboardStatistics? get statistics => _statistics;
  List<NewsItem> get newsList => _newsList;
  List<NoticeItem> get noticesList => _noticesList;
  int get unreadNoticeCount => _unreadNoticeCount;

  bool get isLoadingStatistics => _isLoadingStatistics;
  bool get isLoadingNews => _isLoadingNews;
  bool get isLoadingNotices => _isLoadingNotices;
  bool get isLoading =>
      _isLoadingStatistics || _isLoadingNews || _isLoadingNotices;

  String? get error => _error;
  String? get currentUserId => firebaseAuth.currentUser?.uid;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    final userId = currentUserId;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    // Load all data in parallel
    await Future.wait([
      loadStatistics(),
      loadNews(),
      loadNotices(),
      loadUnreadNoticeCount(),
    ]);
  }

  /// Load dashboard statistics
  Future<void> loadStatistics() async {
    final userId = currentUserId;
    if (userId == null) return;

    _isLoadingStatistics = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await getDashboardStatisticsUseCase.call(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      print('Error loading statistics: $e');
    } finally {
      _isLoadingStatistics = false;
      notifyListeners();
    }
  }

  /// Load latest news
  Future<void> loadNews({int limit = 10}) async {
    _isLoadingNews = true;
    _error = null;
    notifyListeners();

    try {
      _newsList = await getLatestNewsUseCase.call(limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Failed to load news: $e';
      print('Error loading news: $e');
    } finally {
      _isLoadingNews = false;
      notifyListeners();
    }
  }

  /// Load active notices
  Future<void> loadNotices({bool includeExpired = false}) async {
    _isLoadingNotices = true;
    _error = null;
    notifyListeners();

    try {
      _noticesList =
          await getActiveNoticesUseCase.call(includeExpired: includeExpired);
      _error = null;
    } catch (e) {
      _error = 'Failed to load notices: $e';
      print('Error loading notices: $e');
    } finally {
      _isLoadingNotices = false;
      notifyListeners();
    }
  }

  /// Load unread notice count
  Future<void> loadUnreadNoticeCount() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      _unreadNoticeCount = await getUnreadNoticeCountUseCase.call(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading unread notice count: $e');
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get notices filtered by urgency
  List<NoticeItem> getNoticesByUrgency(NoticeUrgency urgency) {
    return _noticesList.where((notice) => notice.urgency == urgency).toList();
  }

  /// Get critical and high urgency notices
  List<NoticeItem> get urgentNotices {
    return _noticesList
        .where((notice) =>
            notice.urgency == NoticeUrgency.critical ||
            notice.urgency == NoticeUrgency.high)
        .toList();
  }

  /// Get recent news (published within last 7 days)
  List<NewsItem> get recentNews {
    return _newsList.where((news) => news.isRecent).toList();
  }

  /// Mark notice as read
  Future<void> markNoticeAsRead(String noticeId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await markNoticeAsReadUseCase.call(userId, noticeId);
      // Reload unread count after marking as read
      await loadUnreadNoticeCount();
    } catch (e) {
      print('Error marking notice as read: $e');
    }
  }
}
