import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srscs/core/theme/app_theme_provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/user_roles.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true; // 👁️ Track password visibility

  /// Validates password strength
  /// Must contain: uppercase, lowercase, number, min 6 characters
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  void _login() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('User ID is null');
      }

      // Get user role from Firestore
      final userRole = await _authService.getUserRole(userId);

      if (userRole == null) {
        // User authenticated but no role found in any collection

        await NotificationService().deleteToken();

        await FirebaseAuth.instance.signOut();
        _showError("Account not found. Please contact administrator.");
        setState(() => _isLoading = false);
        return;
      }

      // Show success message with role
      String roleText = '';
      switch (userRole) {
        case UserRole.citizen:
          roleText = 'Citizen';
          break;
        case UserRole.contractor:
          roleText = 'Contractor';
          break;
        case UserRole.admin:
          roleText = 'Admin';
          break;
      }

      _showMessage("Login Successful as $roleText");

      // Initialize FCM token after successful login
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Subscribe to common topics (all users)
      await notificationService.subscribeToTopic('all_users');
      await notificationService.subscribeToTopic('urgent_notices');

      // Subscribe to role-specific topics
      switch (userRole) {
        case UserRole.citizen:
          await notificationService.subscribeToTopic('citizen_updates');
          break;
        case UserRole.contractor:
          await notificationService.subscribeToTopic('contractor_updates');
          break;
        case UserRole.admin:
          await notificationService.subscribeToTopic('admin_updates');
          break;
      }

      // Navigate to role-specific dashboard
      if (mounted) {
        final theme = Provider.of<AppThemeProvider>(context, listen: false);
        theme.setThemeForRole(userRole);
        final dashboardRoute = AppRoutes.getInitialRoute(userRole.value);
        Get.offAllNamed(dashboardRoute);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login Failed";

      switch (e.code) {
        case 'user-not-found':
          errorMessage =
              "❌ No account found with this email address.\nPlease check your email or register a new account.";
          break;
        case 'wrong-password':
          errorMessage =
              "❌ Incorrect password.\nPlease try again or reset your password.";
          break;
        case 'invalid-email':
          errorMessage =
              "❌ Invalid email format.\nPlease enter a valid email address.";
          break;
        case 'user-disabled':
          errorMessage =
              "❌ This account has been disabled.\nPlease contact administrator for assistance.";
          break;
        case 'too-many-requests':
          errorMessage =
              "⚠️ Too many failed login attempts.\nPlease try again later or reset your password.";
          break;
        case 'invalid-credential':
          errorMessage =
              "❌ Invalid email or password.\nPlease check your credentials and try again.";
          break;
        case 'network-request-failed':
          errorMessage =
              "🌐 Network error.\nPlease check your internet connection.";
          break;
        case 'operation-not-allowed':
          errorMessage =
              "❌ Email/password login is not enabled.\nPlease contact administrator.";
          break;
        default:
          errorMessage = "❌ Login failed: ${e.message ?? 'Unknown error'}";
      }

      _showError(errorMessage);
    } catch (e) {
      _showError(
          "❌ An unexpected error occurred.\nPlease try again later.\n\nDetails: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email:",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password:",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
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
                  validator: _validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password must contain:\n• At least 6 characters\n• One uppercase letter (A-Z)\n• One lowercase letter (a-z)\n• One number (0-9)",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.forgotPassword);
                  },
                  child: const Text("Click Here To Reset Your Password"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.nidVerification);
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
      ),
    );
  }
}
