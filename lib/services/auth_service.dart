import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/user_roles.dart';

class AuthService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> fetchUserProfile(String? userId) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;
    final userRole = await getUserRole(uid);

    if (userRole == UserRole.citizen) {
      final doc = await _firestore.collection('citizens').doc(uid).get();
      return doc.data();
    } else if (userRole == UserRole.contractor) {
      final doc = await _firestore.collection('contractors').doc(uid).get();
      return doc.data();
    } else if (userRole == UserRole.admin) {
      final doc = await _firestore.collection('admins').doc(uid).get();
      return doc.data();
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserComplaints(String? userId) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    final query = await _firestore
        .collection('complaints')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<UserRole?> getUserRole(String userId) async {
    try {
      // Check in citizens collection first
      final citizenDoc =
          await _firestore.collection('citizens').doc(userId).get();
      if (citizenDoc.exists) {
        return UserRole.citizen;
      }

      // Check in contractors collection
      final contractorDoc =
          await _firestore.collection('contractors').doc(userId).get();
      if (contractorDoc.exists) {
        return UserRole.contractor;
      }

      // Check in admins collection
      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (adminDoc.exists) {
        return UserRole.admin;
      }

      return null; // Default
    } catch (e) {
      return null;
    }
  }
}
