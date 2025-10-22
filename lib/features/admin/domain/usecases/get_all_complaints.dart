import '../repositories/admin_repository.dart';

/// Get All Complaints Use Case
///
/// Retrieves all complaints across the system for admin view
class GetAllComplaints {
  final AdminRepository repository;

  GetAllComplaints(this.repository);

  Stream<List<Map<String, dynamic>>> call() {
    return repository.getAllComplaints();
  }
}
