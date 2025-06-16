import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srscs/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class FirebaseService {
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Verify NID
  Future<Map<String, String>?> verifyNID(String nid) async {
    try {
      final user = await FirebaseFirestore.instance
          .collection('NIDRecords')
          .doc(nid)
          .get();
      if (user.exists) {
        final data = user.data()!;
        return {
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'address': data['address'],
          'dob': data['dob'],
          'imageUrl': data['image'],
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerEntry(
    String nidNumber,
    String firstName,
    String lastName,
    String email,
    String phoneNumber,
    String uid,
    String address,
    String dob,
    String imageUrl,
  ) async {
    try {
      await firestore.collection('ApplicationUsers').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'imageUrl': imageUrl,
        'isActive': true,
        'nidNumber': nidNumber,
        'address': address,
        'dob': DateFormat('dd/MM/yyyy').parse(dob),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get User by UID
  Future<UserModel> getUserData(String uid) async {
    DocumentSnapshot snapshot =
        await firestore.collection('ApplicationUsers').doc(uid).get();
    if (snapshot.exists) {
      return UserModel.fromDocumentSnapshot(snapshot);
    } else {
      throw 'User not found';
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await firestore.collection('ApplicationUsers').doc(user.uid).update({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'imageUrl': user.imageUrl,
        'phoneNumber': user.phoneNumber,
      });
    } catch (e) {
      rethrow;
    }
  }

  //Upload image to Firebase Storage
  Future<String> uploadImageToFirebase(File imageFile, String userId) async {
    final storageRef = FirebaseStorage.instance.ref().child(
          'user_avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    final uploadTask = await storageRef.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String?> isUserSignedIn() async {
    User? user = auth.currentUser;
    return user!.uid;
  }
}
