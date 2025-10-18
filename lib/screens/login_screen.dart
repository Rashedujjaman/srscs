import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // 👁️ Track password visibility

  void _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError("⚠ Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      _showMessage("Login Successful");
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Get.offAllNamed('/dashboard');
    } catch (e) {
      _showError("Login Failed: Please check your Gmail or password.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("EG/BN"),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome to Smart Road Safety Complaint System",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logo.jpeg',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              const Text(
                "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Gmail:"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password:",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text("Login"),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Get.toNamed('/forgot');
                },
                child: const Text("Click Here To Reset Your Password"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Get.toNamed('/nid');
                },
                child: const Text(
                  "Don't have an Account?\nRegister now",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Policy & Terms and Conditions",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
