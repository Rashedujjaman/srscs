import 'package:flutter/material.dart';
// import 'package:srscs/screens/login_screen.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/authentication_service.dart';
// import 'package:srscs/services/snackbar_service.dart';
// import 'package:srscs/theme/gradient_provider.dart';
import 'package:srscs/widgets/custom_text_form_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegisterScreen> {
  //*************************************************************************************************************************** */
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  //*************************************************************************************************************************** */

  bool isValidPhoneNumber(String value) {
    final RegExp regex = RegExp(r"^01[0-9]{8,9}$");
    return regex.hasMatch(value);
  }

  bool isValidEmail(String value) {
    final RegExp regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(value);
  }

  Future<void> register() async {
    final String firstName = _firstNameController.text;
    final String lastName = _lastNameController.text;
    final String phoneNumber = _phoneNumberController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      try {
        String uid = await AuthenticationService().createUser(email, password);

        await FirebaseService().registerEntry(
          firstName,
          lastName,
          email,
          phoneNumber,
          uid,
        );

        if (mounted) {
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => const LoginScreen()),
          // );
          // SnackbarService().successMessage(context, 'Registration Successful!');
        }
      } catch (e) {
        if (mounted) {
          // SnackbarService().errorMessage(context, e.toString());
        }
      }
    }
    setState(() => _isLoading = false);
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 50.0),
                        // Title
                        const Center(
                          child: Text(
                            'Register Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50.0),
                        // First Name Field
                        CustomTextFormField(
                          label: 'First Name',
                          controller: _firstNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your First Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Last Name Field
                        CustomTextFormField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Last Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Phone Number Field
                        CustomTextFormField(
                          label: 'Phone Number',
                          controller: _phoneNumberController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Phone Number';
                            }
                            if (!isValidPhoneNumber(value)) {
                              return 'Please enter a valid Phone Number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Email Field
                        CustomTextFormField(
                          label: 'Email',
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Email';
                            }
                            if (!isValidEmail(value)) {
                              return 'Please enter a valid Email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Password Field
                        CustomTextFormField(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a Password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            if (!RegExp(
                              r'^(?=.*[a-zA-Z])(?=.*[0-9])',
                            ).hasMatch(value)) {
                              return 'Password must contain both letters and numbers';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Confirm Password Field
                        CustomTextFormField(
                          label: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your Password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 50.0),
                        // Submit Button
                        ElevatedButton(
                          onPressed: () {
                            !_isLoading &&
                                    _formKey.currentState?.validate() == true
                                ? register()
                                : null;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 16.0),
                        // Navigate to Login Screen
                        TextButton(
                          onPressed: () {
                            // navigate Register Screen
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) {
                            //       return const LoginScreen();
                            //     },
                            //   ),
                            // );
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: Colors.white),
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
