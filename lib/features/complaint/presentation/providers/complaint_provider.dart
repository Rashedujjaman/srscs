import 'package:flutter/material.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/usecases/submit_complaint.dart';
import '../../domain/usecases/get_user_complaints.dart';
import '../../domain/usecases/sync_offline_complaints.dart';

enum ComplaintState { idle, loading, success, error }

class ComplaintProvider extends ChangeNotifier {
  final SubmitComplaint submitComplaintUsecase;
  final GetUserComplaints getUserComplaintsUsecase;
  final SyncOfflineComplaints syncOfflineComplaintsUsecase;

  ComplaintProvider({
    required this.submitComplaintUsecase,
    required this.getUserComplaintsUsecase,
    required this.syncOfflineComplaintsUsecase,
  });

  ComplaintState state = ComplaintState.idle;
  String? errorMessage;
  List<ComplaintEntity> complaints = [];
  int unsyncedCount = 0;

  Future<String?> submitComplaint({
    required String userId,
    required String userName,
    required ComplaintType type,
    required String description,
    required List<String> mediaFiles,
    Map<String, double>? location,
  }) async {
    state = ComplaintState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final complaintId = await submitComplaintUsecase.call(
        userId: userId,
        userName: userName,
        type: type,
        description: description,
        mediaFiles: mediaFiles,
        location: location,
      );
      state = ComplaintState.success;
      notifyListeners();
      return complaintId;
    } catch (e) {
      errorMessage = e.toString();
      state = ComplaintState.error;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadUserComplaints(String userId) async {
    state = ComplaintState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      complaints = await getUserComplaintsUsecase.call(userId);
      state = ComplaintState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = ComplaintState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> syncComplaints() async {
    try {
      await syncOfflineComplaintsUsecase.call();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
    }
  }
}
