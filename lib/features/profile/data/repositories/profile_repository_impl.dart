import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srscs/features/profile/data/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      return await remoteDataSource.getProfile(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String address,
    required String bloodGroup,
    required String dob,
  }) async {
    try {
      final data = {
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'bloodGroup': bloodGroup,
        'dob': dob,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await remoteDataSource.updateProfile(
        userId: userId,
        data: data,
      );
    } catch (e) {
      print('Error in ProfileRepository.updateProfile: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required String photoPath,
  }) async {
    try {
      return await remoteDataSource.uploadProfilePhoto(
        userId: userId,
        photoPath: photoPath,
      );
    } catch (e) {
      print('Error in ProfileRepository.uploadProfilePhoto: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfilePhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await remoteDataSource.updateProfilePhotoUrl(
        userId: userId,
        photoUrl: photoUrl,
      );
    } catch (e) {
      print('Error in ProfileRepository.updateProfilePhotoUrl: $e');
      rethrow;
    }
  }
}
