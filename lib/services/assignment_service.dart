import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Assign complaint to contractor
  Future<void> assignComplaint({
    required String complaintId,
    required String contractorId,
  }) async {
    final adminId = _auth.currentUser!.uid;

    await _firestore.collection('complaints').doc(complaintId).update({
      'assignedTo': contractorId,
      'assignedBy': adminId,
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'inProgress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // TODO: Send notification to contractor
  }

  // Reassign complaint
  Future<void> reassignComplaint({
    required String complaintId,
    required String newContractorId,
  }) async {
    await assignComplaint(
      complaintId: complaintId,
      contractorId: newContractorId,
    );
  }

  // Mark complaint as completed by contractor
  Future<void> markComplaintCompleted({
    required String complaintId,
    String? contractorNotes,
  }) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': 'resolved',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (contractorNotes != null) 'contractorNotes': contractorNotes,
    });

    // TODO: Send notification to user and admin
  }

  // Get unassigned complaints for an area
  Stream<QuerySnapshot> getUnassignedComplaintsByArea(String area) {
    return _firestore
        .collection('complaints')
        .where('area', isEqualTo: area)
        .where('assignedTo', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get contractor's assigned complaints
  Stream<QuerySnapshot> getContractorComplaints(String contractorId) {
    return _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: contractorId)
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }
}
