import '../entities/dashboard_statistics.dart';
import '../entities/news_item.dart';
import '../entities/notice_item.dart';

/// Repository interface for dashboard data operations
abstract class DashboardRepository {
  /// Fetch dashboard statistics for the current user
  Future<DashboardStatistics> getDashboardStatistics(String userId);

  /// Fetch latest news items
  /// [limit] - Maximum number of news items to fetch
  Future<List<NewsItem>> getLatestNews({int limit = 10});

  /// Fetch active notices
  /// [includeExpired] - Whether to include expired notices
  Future<List<NoticeItem>> getActiveNotices({bool includeExpired = false});

  /// Fetch specific notice by ID
  Future<NoticeItem> getNoticeById(String noticeId);
}
