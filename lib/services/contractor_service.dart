import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../features/contractor/data/models/contractor_model.dart';

class ContractorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin creates contractor account
  Future<String?> createContractor({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String assignedArea,
  }) async {
    try {
      FirebaseApp? secondaryApp;
      FirebaseAuth? secondaryAuth;

      try {
        try {
          secondaryApp = Firebase.app('UserCreationApp');
        } catch (e) {
          secondaryApp = await Firebase.initializeApp(
            name: 'UserCreationApp',
            options: Firebase.app().options,
          );
        }

        secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

        UserCredential userCredential = await secondaryAuth
            .createUserWithEmailAndPassword(email: email, password: password);

        final contractorId = userCredential.user!.uid;

        // Create contractor document
        final contractor = ContractorModel(
          id: contractorId,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          assignedArea: assignedArea,
          createdBy: _auth.currentUser!.uid, // Current admin
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('contractors')
            .doc(contractorId)
            .set(contractor.toFirestore());
        await secondaryAuth.signOut();
        return contractorId;
      } catch (e) {
        rethrow;
      } finally {
        if (secondaryApp != null) {
          await secondaryApp.delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get all contractors
  Stream<List<ContractorModel>> getAllContractors() {
    return _firestore
        .collection('contractors')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractorModel.fromFirestore(doc))
            .toList());
  }

  // Get contractors by area
  Stream<List<ContractorModel>> getContractorsByArea(String area) {
    try {
      final contractors = _firestore
          .collection('contractors')
          .where('assignedArea', isEqualTo: area)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ContractorModel.fromFirestore(doc))
              .toList());
      return contractors;
    } catch (e) {
      throw Exception('Failed to get contractors by area: $e');
    }
  }

  // Toggle contractor active status
  Future<void> toggleContractorStatus(String contractorId) async {
    final doc =
        await _firestore.collection('contractors').doc(contractorId).get();
    final currentStatus = doc.data()?['isActive'] ?? true;

    await _firestore
        .collection('contractors')
        .doc(contractorId)
        .update({'isActive': !currentStatus});
  }

  // Update contractor area
  Future<void> updateContractorArea(String contractorId, String newArea) async {
    await _firestore
        .collection('contractors')
        .doc(contractorId)
        .update({'assignedArea': newArea});
  }
}
