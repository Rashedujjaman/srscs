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

  /// Get citizen complaints
  Future<List<ComplaintModel>> getCitizenComplaints(String userId) async {
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
      throw Exception('Failed to fetch user complaints: ${e.toString()}');
    }
  }

  /// Get Contractor complaints
  Future<List<ComplaintModel>> getContractorComplaints(
      String contractorId) async {
    try {
      final snapshot = await firestore
          .collection('complaints')
          .where('assignedTo', isEqualTo: contractorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ComplaintModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contractor complaints: ${e.toString()}');
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
      // Get the complaint to retrieve userId
      final complaintDoc =
          await firestore.collection('complaints').doc(complaintId).get();

      if (!complaintDoc.exists) {
        throw Exception('Complaint not found');
      }

      final complaintData = complaintDoc.data()!;
      final userId = complaintData['userId'] as String?;
      final oldStatus = complaintData['status'] as String?;

      // Update complaint status
      final updateData = {
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      if (assignedTo != null) {
        updateData['assignedTo'] = assignedTo;
      }

      await firestore
          .collection('complaints')
          .doc(complaintId)
          .update(updateData);

      // Update honor score if status changed to resolved or rejected
      if (userId != null && oldStatus != status.value) {
        await _updateHonorScore(
          userId: userId,
          status: status,
        );
      }
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }

  /// Update citizen's honor score based on complaint status
  Future<void> _updateHonorScore({
    required String userId,
    required ComplaintStatus status,
  }) async {
    try {
      // Get current citizen data
      final citizenDoc =
          await firestore.collection('citizens').doc(userId).get();

      if (!citizenDoc.exists) {
        print('⚠️ Citizen not found for honor score update: $userId');
        return;
      }

      final citizenData = citizenDoc.data()!;
      final currentScore = (citizenData['honorScore'] as num?)?.toInt() ?? 100;

      int newScore = currentScore;

      // Update score based on status
      if (status == ComplaintStatus.rejected) {
        // Deduct 10 points for rejected complaint
        newScore = currentScore - 10;
        print('📉 Honor score reduced by 10 points for rejected complaint');
      } else if (status == ComplaintStatus.resolved) {
        // Add 10 points for resolved complaint
        newScore = currentScore + 10;
        print('📈 Honor score increased by 10 points for resolved complaint');
      } else {
        // No honor score change for other statuses
        return;
      }

      // Clamp the score between 0 and 100
      newScore = newScore.clamp(0, 100);

      // Update honor score in Firestore
      await firestore.collection('citizens').doc(userId).update({
        'honorScore': newScore,
        'lastHonorScoreUpdate': FieldValue.serverTimestamp(),
      });

      print(
          '✅ Honor score updated for citizen $userId: $currentScore → $newScore');
    } catch (e) {
      rethrow;
    }
  }

  /// Clear assignment for a specific complaint
  Future<void> clearAssignment(String complaintId) {
    return firestore.collection('complaints').doc(complaintId).update({
      'assignedTo': FieldValue.delete(),
    });
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
