import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

    // call provider usecase
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    await auth.verify(nid, parsedDob);

    setState(() => _isLoading = false);

    if (auth.state == AuthState.error) {
      _showSnackBar(auth.errorMessage ?? 'Verification failed', isError: true);
      return;
    }

    if (auth.state == AuthState.success && auth.verifiedUser != null) {
      final u = auth.verifiedUser!;
      Get.to(() => RegisterScreen(prefilledData: {
            'nid': u.nid,
            'fullName': u.fullName,
            'dob': u.dob,
            'address': u.address ?? '',
            'bloodGroup': u.bloodGroup ?? '',
          }));
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
