import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileRemoteDataSource({
    required this.firestore,
    required this.storage,
  });

  Future<ProfileModel> getProfile(String userId) async {
    try {
      final doc = await firestore.collection('citizens').doc(userId).get();

      if (!doc.exists) {
        throw Exception('Profile not found');
      }

      return ProfileModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestore.collection('citizens').doc(userId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProfilePhoto({
    required String userId,
    required String photoPath,
  }) async {
    try {
      final file = File(photoPath);
      final storageRef =
          storage.ref().child('profile_photos').child('$userId.jpg');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfilePhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await firestore.collection('citizens').doc(userId).update({
        'imageUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
