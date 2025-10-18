import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('citizens').doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchUserComplaints() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final query = await _firestore
        .collection('complaints')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }
}
