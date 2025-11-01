import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _emailCtrl.text = Get.arguments ?? '';
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your registered Email", isError: true);
      return;
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email exists in any user collection
      final emailExists = await _checkEmailExists(email);

      if (!emailExists) {
        _showSnackBar(
          "No account found with this email. Please check your email or register.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // If email exists, send reset link
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Reset link sent. Please check your email.");

      // Navigate back after successful send
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Get.back();
        }
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnackBar("No user found with this Email", isError: true);
      } else if (e.code == 'invalid-email') {
        _showSnackBar("Invalid email format", isError: true);
      } else {
        _showSnackBar("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred. Please try again.",
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Check if email exists in any user collection (citizens, contractors, admins)
  Future<bool> _checkEmailExists(String email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Check in citizens collection
      final citizensQuery = await firestore
          .collection('citizens')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (citizensQuery.docs.isNotEmpty) {
        return true;
      }

      // Check in contractors collection
      final contractorsQuery = await firestore
          .collection('contractors')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (contractorsQuery.docs.isNotEmpty) {
        return true;
      }

      // Check in admins collection
      final adminsQuery = await firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (adminsQuery.docs.isNotEmpty) {
        return true;
      }

      // Email not found in any collection
      return false;
    } catch (e) {
      // Return true to allow Firebase Auth to handle the error
      return true;
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg, textAlign: TextAlign.center),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.jpeg', height: 100),
              const SizedBox(height: 20),
              const Text(
                "Forgot Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your registered Email to receive a reset link",
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendResetLink,
                        child: const Text("Send Reset Link"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
