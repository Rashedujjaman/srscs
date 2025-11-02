import 'package:flutter/material.dart';
import 'package:srscs/features/complaint/domain/usecases/clear_assignment.dart';
import 'package:srscs/features/complaint/domain/usecases/update_complaint_status.dart';
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
  final UpdateComplaintStatus updateComplaintStatusUsecase;
  final ClearAssignment clearAssignmentUseCase;

  ComplaintProvider({
    required this.submitComplaintUsecase,
    required this.getCitizenComplaintsUsecase,
    required this.getContractorComplaintsUsecase,
    required this.syncOfflineComplaintsUsecase,
    required this.updateComplaintStatusUsecase,
    required this.clearAssignmentUseCase,
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

  Future<bool> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
  }) async {
    state = ComplaintState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      // This method should call the appropriate use case to update the complaint status
      await updateComplaintStatusUsecase.call(
        complaintId: complaintId,
        status: status,
        adminNotes: adminNotes,
      );

      state = ComplaintState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = ComplaintState.error;
      notifyListeners();
      return false;
    } finally {
      notifyListeners();
    }
    return true;
  }

  /// Clear assignment for a complaint
  /// Used when rejecting a complaint
  Future<bool> clearAssignment(String complaintId) async {
    try {
      await clearAssignmentUseCase(complaintId);

      return true;
    } catch (e) {
      debugPrint('Error clearing assignment: $e');
      notifyListeners();
      return false;
    }
  }
}
