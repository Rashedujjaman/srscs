import '../../domain/entities/dashboard_statistics.dart';
import '../../domain/entities/news_item.dart';
import '../../domain/entities/notice_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardStatistics> getDashboardStatistics(String userId) async {
    return await remoteDataSource.getDashboardStatistics(userId);
  }

  @override
  Future<List<NewsItem>> getLatestNews({int limit = 10}) async {
    return await remoteDataSource.getLatestNews(limit: limit);
  }

  @override
  Future<List<NoticeItem>> getActiveNotices(
      {bool includeExpired = false}) async {
    return await remoteDataSource.getActiveNotices(
        includeExpired: includeExpired);
  }

  @override
  Future<NoticeItem> getNoticeById(String noticeId) async {
    return await remoteDataSource.getNoticeById(noticeId);
  }
}
