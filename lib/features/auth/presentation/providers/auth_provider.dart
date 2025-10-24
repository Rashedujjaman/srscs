import 'package:flutter/material.dart';
import '../../domain/usecases/verify_nid.dart';
import '../../data/models/user_model.dart';

enum AuthState { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final VerifyNid verifyNidUsecase;

  AuthProvider({required this.verifyNidUsecase});

  AuthState state = AuthState.idle;
  String? errorMessage;
  UserModel? verifiedCitizen;

  Future<void> verify(String nid, String dob) async {
    state = AuthState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final citizen = await verifyNidUsecase.call(nid: nid, dob: dob);
      verifiedCitizen = citizen;
      state = AuthState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    } finally {
      notifyListeners();
    }
  }
}
