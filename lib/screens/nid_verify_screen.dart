import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:srscs/screens/login_screen.dart';
import 'package:srscs/screens/register_screen.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/snackbar_service.dart';
import 'package:srscs/widgets/custom_text_form_field.dart';

class NidVerifyScreen extends StatefulWidget {
  const NidVerifyScreen({super.key});
  @override
  State<NidVerifyScreen> createState() => _NidVerifyScreenState();
}

class _NidVerifyScreenState extends State<NidVerifyScreen> {
  //************************************************************************************************************* */
  final TextEditingController _nidController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Date of Birth';
    }
    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(value);
      if (date.isAfter(DateTime.now())) {
        return 'Date of Birth cannot be in the future';
      }
    } catch (e) {
      return 'Please enter a valid date in DD/MM/YYYY format';
    }
    return null;
  }

  bool _isLoading = false;
  //************************************************************************************************************* */

  @override
  void initState() {
    super.initState();
  }

  void _verifyNID() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the Firebase service to verify NID
      final user = await FirebaseService().verifyNID(_nidController.text);

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        String dob = DateFormat('dd/MM/yyyy').format(
          DateFormat('dd/MM/yyyy').parseStrict(_dateOfBirthController.text),
        );
        // Check if the date of birth matches
        if (user['dob'] != dob) {
          if (mounted) {
            // Show an error message if the date of birth does not match
            SnackbarService().errorMessage(
              context,
              'Date of Birth does not match with NID.',
            );
          }
          return;
        }
        // If verification is successful, navigate to the next screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(
                nidNumber: _nidController.text,
                dateOfBirth: dob,
                firstName: user['firstName'] ?? '',
                lastName: user['lastName'] ?? '',
                address: user['address'] ?? '',
                imageUrl: user['imageUrl'] ?? '',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          // Show an error message if verification fails
          SnackbarService().errorMessage(
            context,
            'NID number not found.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Show an error message if an exception occurs
        SnackbarService().errorMessage(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: double.infinity,
            decoration: BoxDecoration(color: Colors.white),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  // Using a Form widget to validate inputs
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        const Text('Create a new account',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(
                          width: 150,
                          child: Text(
                            'Verify your identity with your NID and date of birth',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 100),
                        CustomTextFormField(
                          label: 'NID Number',
                          keyboardType: TextInputType.number,
                          controller: _nidController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your NID Number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextFormField(
                          label: 'Date of Birth (DD/MM/YYYY)',
                          controller: _dateOfBirthController,
                          validator: (value) => _validateDateOfBirth(value),
                        ),
                        const SizedBox(height: 50.0),

                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _verifyNID();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Verify NID',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 100),
                        // Navigate to Login Screen
                        TextButton(
                          onPressed: () {
                            // navigate Register Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const LoginScreen();
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
