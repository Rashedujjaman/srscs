import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srscs/screens/login_screen.dart';
import 'package:srscs/screens/dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:srscs/services/firebase_options.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> _isLoggedIn(BuildContext context) async {
    try {
      String? uid = await FirebaseService().isUserSignedIn();

      if (uid != null && uid.isNotEmpty) {
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).setUserId(uid);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRSCS',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isLoggedIn(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data == true) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
