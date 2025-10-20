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
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < filePaths.length; i++) {
        try {
          final file = File(filePaths[i]);
          final fileName = '${complaintId}_$i.${filePaths[i].split('.').last}';
          final ref = storage.ref().child('complaints/$complaintId/$fileName');

          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          downloadUrls.add(url);
        } catch (e) {
          print('Error uploading file ${filePaths[i]}: $e');
          throw Exception(
              'Failed to upload file ${filePaths[i].split('/').last}: ${e.toString()}');
        }
      }

      return downloadUrls;
    } catch (e) {
      print('Error in uploadMediaFiles: $e');
      throw Exception('Failed to upload media files: ${e.toString()}');
    }
  }

  /// Submit complaint to Firestore
  Future<String> submitComplaint(ComplaintModel complaint) async {
    try {
      final docRef = await firestore.collection('complaints').add(
            complaint.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      print('Error in submitComplaint: $e');
      throw Exception(
          'Failed to submit complaint to Firestore: ${e.toString()}');
    }
  }

  /// Get user complaints
  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    try {
      final snapshot = await firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ComplaintModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error in getUserComplaints for userId $userId: $e');
      throw Exception('Failed to fetch user complaints: ${e.toString()}');
    }
  }

  /// Get all complaints (admin)
  Future<List<ComplaintModel>> getAllComplaints() async {
    try {
      final snapshot = await firestore
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ComplaintModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error in getAllComplaints: $e');
      throw Exception('Failed to fetch all complaints: ${e.toString()}');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminNotes,
    String? assignedTo,
  }) async {
    try {
      await firestore.collection('complaints').doc(complaintId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (assignedTo != null) 'assignedTo': assignedTo,
      });
    } catch (e) {
      print('Error in updateComplaintStatus for complaintId $complaintId: $e');
      throw Exception('Failed to update complaint status: ${e.toString()}');
    }
  }

  /// Stream complaints for real-time updates
  Stream<List<ComplaintModel>> streamUserComplaints(String userId) {
    try {
      return firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          return snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList();
        } catch (e) {
          print('Error mapping complaint documents: $e');
          throw Exception('Failed to parse complaint data: ${e.toString()}');
        }
      }).handleError((error) {
        print('Error in streamUserComplaints for userId $userId: $error');
        throw Exception(
            'Failed to stream user complaints: ${error.toString()}');
      });
    } catch (e) {
      print('Error initializing streamUserComplaints: $e');
      throw Exception('Failed to initialize complaint stream: ${e.toString()}');
    }
  }
}
