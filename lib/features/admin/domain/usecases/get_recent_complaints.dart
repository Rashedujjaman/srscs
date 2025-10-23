import '../repositories/admin_repository.dart';
import 'package:srscs/features/complaint/domain/entities/complaint_entity.dart';

/// Get Recent Complaints Use Case
///
/// Retrieves recent complaints across the system for admin view
class GetRecentComplaints {
  final AdminRepository repository;
  GetRecentComplaints(this.repository);

  Stream<List<ComplaintEntity>> call() {
    return repository.getRecentComplaints();
  }
}
