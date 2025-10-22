import '../repositories/admin_repository.dart';

/// Get Dashboard Statistics Use Case
///
/// Retrieves system-wide statistics for admin dashboard
class GetDashboardStatistics {
  final AdminRepository repository;

  GetDashboardStatistics(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getDashboardStatistics();
  }
}
