import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class GetUserComplaints {
  final ComplaintRepository repository;

  GetUserComplaints(this.repository);

  Future<List<ComplaintEntity>> call(String userId) async {
    return await repository.getUserComplaints(userId);
  }
}
