import 'package:flutter/material.dart';
// import 'package:srscs/screens/login_screen.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/authentication_service.dart';
// import 'package:srscs/services/snackbar_service.dart';
// import 'package:srscs/theme/gradient_provider.dart';
import 'package:srscs/widgets/custom_text_form_field.dart';

class RegisterScreen extends StatefulWidget {
  final String nidNumber;
  final String dateOfBirth;
  final String firstName;
  final String lastName;
  final String address;
  const RegisterScreen(
      {super.key,
      required this.nidNumber,
      required this.dateOfBirth,
      required this.firstName,
      required this.lastName,
      required this.address});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  //*************************************************************************************************************************** */
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _nidNumber;
  late String _dateOfBirth;
  late String _firstName;
  late String _lastName;
  late String _address;

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

  @override
  void initState() {
    super.initState();
    _nidNumber = widget.nidNumber;
    _dateOfBirth = widget.dateOfBirth;
    _firstName = widget.firstName;
    _lastName = widget.lastName;
    _address = widget.address;
  }

  Future<void> register() async {
    final String firstName = _firstName;
    final String lastName = _lastName;
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
      appBar: AppBar(
        title: const Text('Register'),
        // backgroundColor: Colors.grey,
      ),
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
                        const SizedBox(height: 20.0),

                        Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 0.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'NID Verified Successfully',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'NID Number: $_nidNumber',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Date of Birth: $_dateOfBirth',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'First Name: $_firstName',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Last Name: $_lastName',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Address: $_address',
                                        style: const TextStyle(fontSize: 16),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50.0),

                        Column(
                          children: [
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
                            const SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() == true) {
                                  // Handle form submission
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
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 16.0),

                        // ElevatedButton(
                        //   onPressed: () {
                        //     setState(() {
                        //       _formKey.currentState?.validate();
                        //     });
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.grey,
                        //     padding: const EdgeInsets.symmetric(
                        //         vertical: 8.0, horizontal: 16.0),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8.0),
                        //     ),
                        //   ),
                        //   child: _isLoading
                        //       ? const CircularProgressIndicator(
                        //           valueColor: AlwaysStoppedAnimation<Color>(
                        //             Colors.white,
                        //           ),
                        //         )
                        //       : const Text(
                        //           'Verify NID',
                        //           style: TextStyle(
                        //             fontSize: 16,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        // ),
                        // const SizedBox(height: 16.0),
                        // Navigate to Login Screen
                        // TextButton(
                        //   onPressed: () {
                        //     // navigate Register Screen
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) {
                        //           return const LoginScreen();
                        //         },
                        //       ),
                        //     );
                        //   },
                        //   child: const Text(
                        //     'Already have an account? Login',
                        //     style: TextStyle(color: Colors.grey),
                        //   ),
                        // ),
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
