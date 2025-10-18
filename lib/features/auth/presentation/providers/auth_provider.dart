import 'package:flutter/material.dart';
import '../../domain/usecases/verify_nid.dart';
import '../../domain/entities/user_entity.dart';

enum AuthState { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final VerifyNid verifyNidUsecase;

  AuthProvider({required this.verifyNidUsecase});

  AuthState state = AuthState.idle;
  String? errorMessage;
  UserEntity? verifiedUser;

  Future<void> verify(String nid, DateTime dob) async {
    state = AuthState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await verifyNidUsecase.call(nid: nid, dob: dob);
      verifiedUser = user;
      state = AuthState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    } finally {
      notifyListeners();
    }
  }
}
