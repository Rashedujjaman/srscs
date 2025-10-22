import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

/// Admin Repository Implementation
///
/// Implements the admin repository interface
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Map<String, dynamic>>> getAllComplaints() {
    return remoteDataSource.getAllComplaints();
  }

  @override
  Future<Map<String, dynamic>> getDashboardStatistics() {
    return remoteDataSource.getDashboardStatistics();
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminNotes,
  }) {
    return remoteDataSource.updateComplaintStatus(
      complaintId: complaintId,
      status: status,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<Map<String, dynamic>?> getComplaintById(String complaintId) {
    return remoteDataSource.getComplaintById(complaintId);
  }
}
