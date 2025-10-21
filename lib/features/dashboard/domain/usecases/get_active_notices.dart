import '../entities/notice_item.dart';
import '../repositories/dashboard_repository.dart';

/// Use case for fetching active notices
class GetActiveNotices {
  final DashboardRepository repository;

  GetActiveNotices(this.repository);

  Future<List<NoticeItem>> call({bool includeExpired = false}) async {
    return await repository.getActiveNotices(includeExpired: includeExpired);
  }
}
