import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/nid_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SRSCS',
      debugShowCheckedModeBanner: false,
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/dashboard',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
            name: '/register',
            page: () => RegisterScreen(prefilledData: const {})),
        GetPage(name: '/forgot', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/nid', page: () => const NIDVerificationScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
      ],
    );
  }
}
