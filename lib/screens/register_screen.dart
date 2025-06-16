import 'package:flutter/material.dart';
// import 'package:srscs/screens/login_screen.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/authentication_service.dart';
// import 'package:srscs/services/snackbar_service.dart';
// import 'package:srscs/theme/gradient_provider.dart';
import 'package:srscs/widgets/custom_text_form_field.dart';
import 'package:srscs/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String nidNumber;
  final String dateOfBirth;
  final String firstName;
  final String lastName;
  final String address;
  final String imageUrl;
  const RegisterScreen(
      {super.key,
      required this.nidNumber,
      required this.dateOfBirth,
      required this.firstName,
      required this.lastName,
      required this.address,
      required this.imageUrl});
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
  late String _imageUrl;

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
    _imageUrl = widget.imageUrl;
  }

  Future<void> register() async {
    final String phoneNumber = _phoneNumberController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      try {
        String uid = await AuthenticationService().createUser(email, password);

        await FirebaseService().registerEntry(
          _nidNumber,
          _firstName,
          _lastName,
          email,
          phoneNumber,
          uid,
          _address,
          _dateOfBirth,
          _imageUrl,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          // SnackbarService().successMessage(context, 'Registration Successful!');
          AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('You can now log in with your credentials.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        }
      } catch (e) {
        if (mounted) {
          // SnackbarService().errorMessage(context, e.toString());
          AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
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
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 0.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'NID Verified',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 25.0,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(
                                        _imageUrl,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 0,
                                        children: [
                                          Text(
                                            'NID Number: $_nidNumber',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Date of Birth: $_dateOfBirth',
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'First Name: $_firstName',
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Last Name: $_lastName',
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Address: $_address',
                                            style:
                                                const TextStyle(fontSize: 16),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
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
                                  register();
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
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            )
                          ],
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
