import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  final Map<String, dynamic> prefilledData;

  const RegisterScreen({super.key, required this.prefilledData});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (email.isEmpty || phone.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showError("Please fill all fields.");
      return;
    }

    if (pass != confirm) {
      _showError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);
    UserCredential? authResult;

    try {
      // Step 1: Create Firebase Auth user
      authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = authResult.user!.uid;

      // Step 2: Prepare Firestore data
      final fullName = widget.prefilledData['fullName']?.toString() ?? '';
      final nid = widget.prefilledData['nid']?.toString() ?? '';
      final address = widget.prefilledData['address']?.toString() ?? '';
      final blood = widget.prefilledData['bloodGroup']?.toString() ?? '';
      final dob = widget.prefilledData['dob'];

      // Step 3: Save Firestore user data
      await FirebaseFirestore.instance.collection('citizens').doc(uid).set({
        'uid': uid,
        'nid': nid,
        'fullName': fullName,
        'dob': dob is Timestamp
            ? dob
            : Timestamp.fromDate(DateTime.parse(dob.toString())),
        'address': address,
        'bloodGroup': blood,
        'email': email,
        'phone': phone,
        'createdAt': Timestamp.now(),
      });

      // Step 4: Send email verification
      await authResult.user!.sendEmailVerification();

      _showMessage("Registration successful! Please verify your email.");
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) Get.offAllNamed('/login');
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
    final data = widget.prefilledData;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _readonlyField("NID Number", data['nid'] ?? ''),
            _readonlyField("Full Name", data['fullName'] ?? ''),
            _readonlyField("Date of Birth", _formatDate(data['dob'])),
            _readonlyField("Address", data['address'] ?? ''),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Gmail"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
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

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
    return timestamp.toString();
  }
}
