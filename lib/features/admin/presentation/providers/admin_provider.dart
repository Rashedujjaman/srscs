import 'package:flutter/foundation.dart';
import 'package:srscs/features/admin/domain/usecases/clear_assignment.dart';
import '../../domain/usecases/get_all_complaints.dart';
import '../../domain/usecases/get_dashboard_statistics.dart';
import '../../domain/usecases/update_complaint_status.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';

/// Admin Provider
///
/// Manages state for admin features
class AdminProvider with ChangeNotifier {
  final GetAllComplaints getAllComplaintsUseCase;
  final GetDashboardStatistics getDashboardStatisticsUseCase;
  final UpdateComplaintStatus updateComplaintStatusUseCase;
  final ClearAssignment clearAssignmentUseCase;

  AdminProvider({
    required this.getAllComplaintsUseCase,
    required this.getDashboardStatisticsUseCase,
    required this.updateComplaintStatusUseCase,
    required this.clearAssignmentUseCase,
  });

  // State
  final List<Map<String, dynamic>> _complaints = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get complaints => _complaints;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed statistics
  int get totalComplaints => _statistics?['totalComplaints'] ?? 0;
  int get pendingComplaints => _statistics?['pendingComplaints'] ?? 0;
  int get inProgressComplaints => _statistics?['inProgressComplaints'] ?? 0;
  int get resolvedComplaints => _statistics?['resolvedComplaints'] ?? 0;
  int get underReviewComplaints => _statistics?['underReviewComplaints'] ?? 0;
  int get rejectedComplaints => _statistics?['rejectedComplaints'] ?? 0;
  int get totalContractors => _statistics?['totalContractors'] ?? 0;
  int get activeContractors => _statistics?['activeContractors'] ?? 0;
  int get totalCitizens => _statistics?['totalCitizens'] ?? 0;
  int get assignedComplaints => _statistics?['assignedComplaints'] ?? 0;
  int get unassignedComplaints => _statistics?['unassignedComplaints'] ?? 0;

  /// Load dashboard statistics
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await getDashboardStatisticsUseCase();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading statistics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stream all complaints
  Stream<List<ComplaintEntity>> streamAllComplaints() {
    return getAllComplaintsUseCase();
  }

  /// Update complaint status
  Future<bool> updateStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
  }) async {
    try {
      await updateComplaintStatusUseCase(
        complaintId: complaintId,
        status: status,
        adminNotes: adminNotes,
      );

      // Reload statistics after update
      await loadStatistics();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating complaint status: $e');
      notifyListeners();
      return false;
    }
  }

  /// Clear assignment for a complaint
  /// Used when rejecting a complaint
  Future<bool> clearAssignment(String complaintId) async {
    try {
      await clearAssignmentUseCase(complaintId);

      // Reload statistics after update
      await loadStatistics();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error clearing assignment: $e');
      notifyListeners();
      return false;
    }
  }

  /// Filter complaints by status
  List<Map<String, dynamic>> filterByStatus(String? status) {
    if (status == null) return _complaints;
    return _complaints.where((c) => c['status'] == status).toList();
  }

  /// Search complaints
  List<Map<String, dynamic>> searchComplaints(String query) {
    if (query.isEmpty) return _complaints;

    final lowerQuery = query.toLowerCase();
    return _complaints.where((c) {
      final type = (c['type'] ?? '').toString().toLowerCase();
      final description = (c['description'] ?? '').toString().toLowerCase();
      final userName = (c['userName'] ?? '').toString().toLowerCase();
      final status = (c['status'] ?? '').toString().toLowerCase();

      return type.contains(lowerQuery) ||
          description.contains(lowerQuery) ||
          userName.contains(lowerQuery) ||
          status.contains(lowerQuery);
    }).toList();
  }
}
