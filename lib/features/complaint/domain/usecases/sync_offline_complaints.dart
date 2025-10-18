import '../repositories/complaint_repository.dart';

class SyncOfflineComplaints {
  final ComplaintRepository repository;

  SyncOfflineComplaints(this.repository);

  Future<void> call() async {
    return await repository.syncOfflineComplaints();
  }
}
