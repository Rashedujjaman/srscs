import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';

// Auth
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/nid_verification_screen.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/verify_nid.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// Dashboard & Profile
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/usecases/get_profile.dart';
import 'features/profile/domain/usecases/update_profile.dart';
import 'features/profile/domain/usecases/update_profile_photo.dart';
import 'features/profile/presentation/providers/profile_provider.dart';

// Complaint
import 'features/complaint/presentation/screens/submit_complaint_screen.dart';
import 'features/complaint/presentation/screens/complaint_tracking_screen.dart';
import 'features/complaint/data/datasources/complaint_local_data_source.dart';
import 'features/complaint/data/datasources/complaint_remote_data_source.dart';
import 'features/complaint/data/repositories/complaint_repository_impl.dart';
import 'features/complaint/domain/usecases/submit_complaint.dart';
import 'features/complaint/domain/usecases/get_user_complaints.dart';
import 'features/complaint/domain/usecases/sync_offline_complaints.dart';
import 'features/complaint/presentation/providers/complaint_provider.dart';

// Chat
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

// Admin
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth dependencies
    final firestore = FirebaseFirestore.instance;
    final authRemote = AuthRemoteDataSourceImpl(firestore: firestore);
    final authRepo =
        AuthRepositoryImpl(remote: authRemote, firestore: firestore);
    final verifyNidUsecase = VerifyNid(authRepo);

    // Complaint dependencies
    final complaintLocal = ComplaintLocalDataSource();
    final complaintRemote = ComplaintRemoteDataSource(
      firestore: firestore,
      storage: FirebaseStorage.instance,
    );
    final complaintRepo = ComplaintRepositoryImpl(
      remote: complaintRemote,
      local: complaintLocal,
      connectivity: Connectivity(),
    );
    final submitComplaintUsecase = SubmitComplaint(complaintRepo);
    final getUserComplaintsUsecase = GetUserComplaints(complaintRepo);
    final syncOfflineComplaintsUsecase = SyncOfflineComplaints(complaintRepo);

    // Chat dependencies
    final chatRemote =
        ChatRemoteDataSource(database: FirebaseDatabase.instance);
    final chatRepo = ChatRepositoryImpl(remote: chatRemote);
    final sendMessageUsecase = SendMessage(chatRepo);

    // Profile dependencies
    final profileRemote = ProfileRemoteDataSource(
      firestore: firestore,
      storage: FirebaseStorage.instance,
    );
    final profileRepo = ProfileRepositoryImpl(remoteDataSource: profileRemote);
    final getProfileUsecase = GetProfile(profileRepo);
    final updateProfileUsecase = UpdateProfile(profileRepo);
    final updateProfilePhotoUsecase = UpdateProfilePhoto(profileRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(verifyNidUsecase: verifyNidUsecase),
        ),
        ChangeNotifierProvider(
          create: (_) => ComplaintProvider(
            submitComplaintUsecase: submitComplaintUsecase,
            getUserComplaintsUsecase: getUserComplaintsUsecase,
            syncOfflineComplaintsUsecase: syncOfflineComplaintsUsecase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            sendMessageUsecase: sendMessageUsecase,
            repository: chatRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            getProfileUseCase: getProfileUsecase,
            updateProfileUseCase: updateProfileUsecase,
            updateProfilePhotoUseCase: updateProfilePhotoUsecase,
            firebaseAuth: fb_auth.FirebaseAuth.instance,
          ),
        ),
      ],
      child: GetMaterialApp(
        title: 'SRSCS',
        debugShowCheckedModeBanner: false,
        initialRoute: fb_auth.FirebaseAuth.instance.currentUser == null
            ? '/login'
            : '/dashboard',
        getPages: [
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(
              name: '/register',
              page: () => RegisterScreen(prefilledData: const {})),
          GetPage(name: '/forgot', page: () => const ForgotPasswordScreen()),
          GetPage(name: '/nid', page: () => const NIDVerificationScreen()),
          GetPage(name: '/dashboard', page: () => const DashboardScreen()),
          GetPage(name: '/profile', page: () => const ProfileScreen()),
          GetPage(name: '/submit', page: () => const SubmitComplaintScreen()),
          GetPage(
              name: '/tracking', page: () => const ComplaintTrackingScreen()),
          GetPage(name: '/chat', page: () => const ChatScreen()),
          GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
        ],
      ),
    );
  }
}
