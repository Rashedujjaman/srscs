import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/update_profile_photo.dart';

class ProfileProvider with ChangeNotifier {
  final GetProfile getProfileUseCase;
  final UpdateProfile updateProfileUseCase;
  final UpdateProfilePhoto updateProfilePhotoUseCase;
  final FirebaseAuth firebaseAuth;

  ProfileProvider({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.updateProfilePhotoUseCase,
    required this.firebaseAuth,
  });

  ProfileEntity? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => firebaseAuth.currentUser?.uid;

  Future<void> loadProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await getProfileUseCase(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required String bloodGroup,
    required String dob,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await updateProfileUseCase(
        userId: userId,
        fullName: fullName,
        phone: phone,
        address: address,
        bloodGroup: bloodGroup,
        dob: dob,
      );

      // Reload profile to get updated data
      await loadProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(String photoPath) async {
    final userId = currentUserId;
    if (userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photoUrl = await updateProfilePhotoUseCase(
        userId: userId,
        photoPath: photoPath,
      );

      // Update local profile data
      if (_profile != null) {
        _profile = _profile!.copyWith(profilePhotoUrl: photoUrl);
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error updating profile photo: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
