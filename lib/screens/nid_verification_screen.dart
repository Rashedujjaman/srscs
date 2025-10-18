import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_screen.dart';

class NIDVerificationScreen extends StatefulWidget {
  final String nid;
  final String dob;

  const NIDVerificationScreen({
    super.key,
    this.nid = '',
    this.dob = '',
  });

  @override
  State<NIDVerificationScreen> createState() => _NIDVerificationScreenState();
}

class _NIDVerificationScreenState extends State<NIDVerificationScreen> {
  final TextEditingController _nidCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _nidCtrl.text = widget.nid;
    _dobCtrl.text = widget.dob;
  }

  void _verify() async {
    final String nid = _nidCtrl.text.trim();
    final String dobInput = _dobCtrl.text.trim();

    if (nid.isEmpty || dobInput.isEmpty) {
      _showSnackBar("Please enter both NID and Date of Birth", isError: true);
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar("Please agree to the Terms & Conditions", isError: true);
      return;
    }

    DateTime? parsedDob;
    try {
      final temp = DateTime.parse(dobInput); // from user input
      parsedDob = DateTime(temp.year, temp.month, temp.day); // match Firestore
    } catch (_) {
      _showSnackBar("Invalid date format. Use YYYY-MM-DD", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nidResult = await FirebaseFirestore.instance
          .collection('nid_sample')
          .where('nid', isEqualTo: nid)
          .where('dob', isEqualTo: Timestamp.fromDate(parsedDob))
          .get();

      if (nidResult.docs.isEmpty) {
        _showSnackBar("No matching NID found", isError: true);
        return;
      }

      final userData = nidResult.docs.first.data();

      final existing = await FirebaseFirestore.instance
          .collection('citizens')
          .where('nid', isEqualTo: nid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnackBar(
            "Account already exists. Please log in or reset your password.",
            isError: true);
        return;
      }

      Get.to(() => RegisterScreen(prefilledData: {
            'nid': userData['nid'] ?? '',
            'fullName': userData['fullName'] ?? '',
            'dob': userData['dob'],
            'address': userData['address'] ?? '',
            'bloodGroup': userData['bloodGroup'] ?? '',
          }));
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo.jpeg', height: 100),
              const SizedBox(height: 20),

              const Text(
                "Create New Account",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text(
                "Verify using your NID and Date of Birth",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _nidCtrl,
                decoration: const InputDecoration(
                  labelText: "NID Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );

                  if (pickedDate != null) {
                    String formattedDate = pickedDate
                        .toIso8601String()
                        .split('T')
                        .first; // YYYY-MM-DD
                    setState(() {
                      _dobCtrl.text = formattedDate;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      child: const Text(
                        "I agree to the Terms & Conditions",
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verify,
                        child: const Text("Verify"),
                      ),
                    ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Get.offAllNamed('/login'),
                child: const Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
