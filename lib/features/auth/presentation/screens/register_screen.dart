import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:srscs/core/routes/app_routes.dart';
import 'package:srscs/features/auth/data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  late UserModel citizenData;

  @override
  void initState() {
    super.initState();
    citizenData = Get.arguments as UserModel;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    setState(() => _isLoading = true);
    UserCredential? authResult;

    try {
      // Step 1: Create Firebase Auth user
      authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = authResult.user!.uid;

      // Step 2: Prepare Firestore data
      final newUserData = citizenData.toFirestore();
      newUserData['phoneNumber'] = phone;
      newUserData['email'] = email;
      newUserData['createdAt'] = FieldValue.serverTimestamp();
      newUserData['role'] = 'citizen';
      newUserData['honorScore'] = 100;

      // Step 3: Save Firestore user data
      await FirebaseFirestore.instance
          .collection('citizens')
          .doc(uid)
          .set(newUserData);

      // Step 4: Send email verification
      await authResult.user!.sendEmailVerification();

      _showMessage("Registration successful! Please verify your email.");
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      // Rollback Firebase user if Firestore write fails
      if (authResult?.user != null) {
        await authResult!.user!.delete();
      }
      _showError("Registration failed: ${e.toString()}");
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
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (citizenData.imageUrl != null &&
                  citizenData.imageUrl!.isNotEmpty) ...[
                _buildImageSection(),
              ],
              const SizedBox(height: 20),
              _readonlyField("NID Number", citizenData.nid),
              _readonlyField("Full Name", citizenData.fullName),
              _readonlyField("Date of Birth", citizenData.dob),
              _readonlyField("Address", citizenData.address),
              _readonlyField("Blood Group", citizenData.bloodGroup),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Gmail",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  // Bangladesh phone number validation (11 digits starting with 01)
                  final phoneRegex = RegExp(r'^01[0-9]{9}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid BD phone number (01XXXXXXXXX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readonlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        enabled: false,
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = citizenData.imageUrl;
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? const Icon(Icons.person, size: 60, color: Colors.white)
          : null,
    );
  }
}
