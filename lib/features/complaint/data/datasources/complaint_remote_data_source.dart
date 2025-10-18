import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/complaint_model.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ComplaintRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  /// Upload media files to Firebase Storage
  Future<List<String>> uploadMediaFiles(
      List<String> filePaths, String complaintId) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < filePaths.length; i++) {
      final file = File(filePaths[i]);
      final fileName = '${complaintId}_$i.${filePaths[i].split('.').last}';
      final ref = storage.ref().child('complaints/$complaintId/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  /// Submit complaint to Firestore
  Future<String> submitComplaint(ComplaintModel complaint) async {
    final docRef = await firestore.collection('complaints').add(
          complaint.toFirestore(),
        );
    return docRef.id;
  }

  /// Get user complaints
  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final snapshot = await firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ComplaintModel.fromFirestore(doc))
        .toList();
  }

  /// Get all complaints (admin)
  Future<List<ComplaintModel>> getAllComplaints() async {
    final snapshot = await firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ComplaintModel.fromFirestore(doc))
        .toList();
  }

  /// Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
    String? assignedTo,
  }) async {
    await firestore.collection('complaints').doc(complaintId).update({
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (assignedTo != null) 'assignedTo': assignedTo,
    });
  }

  /// Stream complaints for real-time updates
  Stream<List<ComplaintModel>> streamUserComplaints(String userId) {
    return firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList());
  }
}
