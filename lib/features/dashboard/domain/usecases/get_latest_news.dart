import '../entities/news_item.dart';
import '../repositories/dashboard_repository.dart';

/// Use case for fetching latest news items
class GetLatestNews {
  final DashboardRepository repository;

  GetLatestNews(this.repository);

  Future<List<NewsItem>> call({int limit = 10}) async {
    return await repository.getLatestNews(limit: limit);
  }
}
