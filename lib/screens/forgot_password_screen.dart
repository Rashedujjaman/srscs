import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  void _sendResetLink() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your registered Gmail", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Reset link sent. Please check your Gmail.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnackBar("No user found with this Gmail", isError: true);
      } else {
        _showSnackBar("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Unexpected error", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
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
                "Enter your registered Gmail to receive a reset link",
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Gmail",
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
