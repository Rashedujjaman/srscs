import '../entities/dashboard_statistics.dart';
import '../repositories/dashboard_repository.dart';

/// Use case for fetching dashboard statistics
class GetDashboardStatistics {
  final DashboardRepository repository;

  GetDashboardStatistics(this.repository);

  Future<DashboardStatistics> call(String userId) async {
    return await repository.getDashboardStatistics(userId);
  }
}
