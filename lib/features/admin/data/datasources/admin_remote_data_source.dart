import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../complaint/domain/entities/complaint_entity.dart';
import '../../../complaint/data/models/complaint_model.dart';

/// Admin Remote Data Source
///
/// Handles Firestore operations for admin features
class AdminRemoteDataSource {
  final FirebaseFirestore firestore;

  AdminRemoteDataSource({required this.firestore});

  /// Stream all complaints
  Stream<List<ComplaintEntity>> getAllComplaints() {
    return firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Stream recent complaints (last 3)
  Stream<List<ComplaintEntity>> getRecentComplaints() {
    return firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      // Get all complaints
      final complaintsSnapshot = await firestore.collection('complaints').get();
      final complaints = complaintsSnapshot.docs;

      // Get all contractors
      final contractorsSnapshot =
          await firestore.collection('contractors').get();
      final contractors = contractorsSnapshot.docs;

      // Get all citizens
      final citizensSnapshot = await firestore.collection('citizens').get();

      // Calculate statistics
      final totalComplaints = complaints.length;
      final pendingComplaints =
          complaints.where((doc) => doc.data()['status'] == 'pending').length;
      final inProgressComplaints = complaints
          .where((doc) => doc.data()['status'] == 'inProgress')
          .length;
      final resolvedComplaints =
          complaints.where((doc) => doc.data()['status'] == 'resolved').length;
      final underReviewComplaints = complaints
          .where((doc) => doc.data()['status'] == 'underReview')
          .length;
      final rejectedComplaints =
          complaints.where((doc) => doc.data()['status'] == 'rejected').length;

      final totalContractors = contractors.length;
      final activeContractors =
          contractors.where((doc) => doc.data()['isActive'] == true).length;

      final totalCitizens = citizensSnapshot.docs.length;

      // Get assigned complaints
      final assignedComplaints =
          complaints.where((doc) => doc.data()['assignedTo'] != null).length;

      // Get unassigned complaints
      final unassignedComplaints = complaints
          .where((doc) =>
              doc.data()['assignedTo'] == null &&
              doc.data()['status'] != 'resolved' &&
              doc.data()['status'] != 'rejected')
          .length;

      return {
        'totalComplaints': totalComplaints,
        'pendingComplaints': pendingComplaints,
        'inProgressComplaints': inProgressComplaints,
        'resolvedComplaints': resolvedComplaints,
        'underReviewComplaints': underReviewComplaints,
        'rejectedComplaints': rejectedComplaints,
        'totalContractors': totalContractors,
        'activeContractors': activeContractors,
        'totalCitizens': totalCitizens,
        'assignedComplaints': assignedComplaints,
        'unassignedComplaints': unassignedComplaints,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard statistics: $e');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await firestore
          .collection('complaints')
          .doc(complaintId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }

  /// Get complaint by ID
  Future<Map<String, dynamic>?> getComplaintById(String complaintId) async {
    try {
      final doc =
          await firestore.collection('complaints').doc(complaintId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw Exception('Failed to get complaint: $e');
    }
  }
}
