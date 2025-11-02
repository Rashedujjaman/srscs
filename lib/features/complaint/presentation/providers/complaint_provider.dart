import 'package:flutter/material.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/usecases/submit_complaint.dart';
import '../../domain/usecases/get_citizen_complaints.dart';
import '../../domain/usecases/get_contractor_complaints.dart';
import '../../domain/usecases/sync_offline_complaints.dart';

enum ComplaintState { idle, loading, success, error }

class ComplaintProvider extends ChangeNotifier {
  final SubmitComplaint submitComplaintUsecase;
  final GetCitizenComplaints getCitizenComplaintsUsecase;
  final GetContractorComplaints getContractorComplaintsUsecase;
  final SyncOfflineComplaints syncOfflineComplaintsUsecase;

  ComplaintProvider({
    required this.submitComplaintUsecase,
    required this.getCitizenComplaintsUsecase,
    required this.getContractorComplaintsUsecase,
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
    String? area,
    String? landmark,
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
        area: area,
        landmark: landmark,
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

  Future<void> loadCitizenComplaints(String userId) async {
    state = ComplaintState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      complaints = await getCitizenComplaintsUsecase.call(userId);
      state = ComplaintState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = ComplaintState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadContractorComplaints(String contractorId) async {
    state = ComplaintState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      complaints = await getContractorComplaintsUsecase.call(contractorId);
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
