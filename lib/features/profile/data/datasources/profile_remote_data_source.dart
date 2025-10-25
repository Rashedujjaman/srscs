import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/constants/user_roles.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileRemoteDataSource({
    required this.firestore,
    required this.storage,
  });

  Future<ProfileModel> getProfile(String userId) async {
    try {
      // Determine collection based on user role
      final authService = AuthService();
      final userRole = await authService.getUserRole(userId);

      String collection;
      if (userRole == UserRole.citizen) {
        collection = 'citizens';
      } else if (userRole == UserRole.contractor) {
        collection = 'contractors';
      } else if (userRole == UserRole.admin) {
        collection = 'admins';
      } else {
        collection = 'citizens'; // fallback
      }

      final doc = await firestore.collection(collection).doc(userId).get();

      if (!doc.exists) {
        throw Exception('Profile not found in $collection collection');
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
      // Determine collection based on user role
      final authService = AuthService();
      final userRole = await authService.getUserRole(userId);

      String collection;
      if (userRole == UserRole.citizen) {
        collection = 'citizens';
      } else if (userRole == UserRole.contractor) {
        collection = 'contractors';
      } else if (userRole == UserRole.admin) {
        collection = 'admins';
      } else {
        collection = 'citizens'; // fallback
      }

      await firestore.collection(collection).doc(userId).update(data);
    } catch (e) {
      print('❌ Error in updateProfile: $e');
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
      // Determine collection based on user role
      final authService = AuthService();
      final userRole = await authService.getUserRole(userId);

      String collection;
      if (userRole == UserRole.citizen) {
        collection = 'citizens';
      } else if (userRole == UserRole.contractor) {
        collection = 'contractors';
      } else if (userRole == UserRole.admin) {
        collection = 'admins';
      } else {
        collection = 'citizens'; // fallback
      }

      await firestore.collection(collection).doc(userId).update({
        'imageUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error in updateProfilePhotoUrl: $e');
      rethrow;
    }
  }
}
