import 'package:srscs/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  Future<String> createUser(String userEmail, String userPassword) async {
    try {
      UserCredential userCredential = await FirebaseService().auth
          .createUserWithEmailAndPassword(
            email: userEmail,
            password: userPassword,
          );
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred while creating the user. Please try again later.';
    }
  }

  Future<String> signIn(String userEmail, String userPassword) async {
    try {
      UserCredential userCredential = await FirebaseService().auth
          .signInWithEmailAndPassword(email: userEmail, password: userPassword);
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      return 'An error occurred while signing in. Please try again later.';
    }
  }

  // Sign out user
  Future<bool> signOut() async {
    try {
      await FirebaseService().auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred while signing out. Please try again later.';
    }
  }

  // Check if user is signed in
  Future<String?> isUserSignedIn() async {
    User? currentUser = FirebaseService().auth.currentUser;
    return currentUser!.uid;
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'The provided credential is invalid.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
