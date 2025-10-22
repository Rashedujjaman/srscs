import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/routes/app_routes.dart';

/// Splash Screen - Checks authentication and redirects based on role
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not authenticated, go to login
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      // Get user role
      final userRole = await _authService.getUserRole(user.uid);

      if (userRole == null) {
        // User authenticated but no role found
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      // Navigate to role-specific dashboard
      final dashboardRoute = AppRoutes.getInitialRoute(
        userRole.toString().split('.').last,
      );
      Get.offAllNamed(dashboardRoute);
    } catch (e) {
      // Error checking role, go to login
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.jpeg',
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'Smart Road Safety\nComplaint System',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
