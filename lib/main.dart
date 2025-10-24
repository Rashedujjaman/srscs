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

// Core Routes
import 'core/routes/app_routes.dart';
import 'core/routes/route_manager.dart';
import 'core/routes/route_guard_middleware.dart';

// Auth
import 'features/auth/presentation/screens/splash_screen.dart';
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
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/usecases/get_dashboard_statistics.dart';
import 'features/dashboard/domain/usecases/get_latest_news.dart';
import 'features/dashboard/domain/usecases/get_active_notices.dart';
import 'features/dashboard/domain/usecases/get_unread_notice_count.dart';
import 'features/dashboard/domain/usecases/mark_notice_as_read.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';

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
import 'features/chat/presentation/screens/admin_chat_list_screen.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

// Admin
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_complaints_screen.dart';
import 'features/admin/presentation/screens/admin_complaint_detail_screen.dart';
import 'features/admin/presentation/screens/admin_assignment_screen.dart';
import 'features/admin/presentation/screens/admin_contractors_screen.dart';
import 'features/admin/presentation/screens/admin_contractor_detail_screen.dart';
import 'features/admin/presentation/screens/admin_create_contractor_screen.dart';
import 'features/admin/presentation/screens/admin_settings_screen.dart';
import 'features/admin/data/datasources/admin_remote_data_source.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/domain/usecases/get_all_complaints.dart'
    as admin_usecases;
import 'features/admin/domain/usecases/get_dashboard_statistics.dart'
    as admin_usecases;
import 'features/admin/domain/usecases/update_complaint_status.dart'
    as admin_usecases;
import 'features/admin/presentation/providers/admin_provider.dart';

// Contractor
import 'features/contractor/presentation/screens/contractor_dashboard_screen.dart';
import 'features/contractor/presentation/screens/contractor_tasks_screen.dart';
import 'features/contractor/presentation/screens/contractor_task_detail_screen.dart';
import 'features/contractor/presentation/screens/contractor_completed_tasks_screen.dart';

// ONE-TIME DATABASE SEEDER (uncomment to run once, then comment out again)
// import 'features/dashboard/data/datasources/seed_dashboard_data.dart';

// Notification Service
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Configure Firebase Realtime Database
  // ⚠️ Use the DATABASE URL, not the console URL!
  // Correct format: https://PROJECT-ID-default-rtdb.REGION.firebasedatabase.app/
  FirebaseDatabase.instance.databaseURL =
      'https://srscs-58227-default-rtdb.asia-southeast1.firebasedatabase.app/';

  // Initialize Push Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Subscribe to general topics
  await notificationService.subscribeToTopic('all_users');
  await notificationService.subscribeToTopic('urgent_notices');

  // ⚠️ ONE-TIME SEEDING - UNCOMMENT BELOW, RUN ONCE, THEN COMMENT OUT AGAIN ⚠️
  // await seedDashboardData();

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

    // Dashboard dependencies
    final dashboardRemote = DashboardRemoteDataSource(firestore: firestore);
    final dashboardRepo =
        DashboardRepositoryImpl(remoteDataSource: dashboardRemote);
    final getDashboardStatisticsUsecase = GetDashboardStatistics(dashboardRepo);
    final getLatestNewsUsecase = GetLatestNews(dashboardRepo);
    final getActiveNoticesUsecase = GetActiveNotices(dashboardRepo);
    final getUnreadNoticeCountUsecase = GetUnreadNoticeCount(dashboardRepo);
    final markNoticeAsReadUsecase = MarkNoticeAsRead(dashboardRepo);

    // Admin dependencies
    final adminRemote = AdminRemoteDataSource(firestore: firestore);
    final adminRepo = AdminRepositoryImpl(remoteDataSource: adminRemote);
    final getAllComplaintsUsecase = admin_usecases.GetAllComplaints(adminRepo);
    final getAdminDashboardStatisticsUsecase =
        admin_usecases.GetDashboardStatistics(adminRepo);
    final updateComplaintStatusUsecase =
        admin_usecases.UpdateComplaintStatus(adminRepo);

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
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            getDashboardStatisticsUseCase: getDashboardStatisticsUsecase,
            getLatestNewsUseCase: getLatestNewsUsecase,
            getActiveNoticesUseCase: getActiveNoticesUsecase,
            getUnreadNoticeCountUseCase: getUnreadNoticeCountUsecase,
            markNoticeAsReadUseCase: markNoticeAsReadUsecase,
            firebaseAuth: fb_auth.FirebaseAuth.instance,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            getAllComplaintsUseCase: getAllComplaintsUsecase,
            getDashboardStatisticsUseCase: getAdminDashboardStatisticsUsecase,
            updateComplaintStatusUseCase: updateComplaintStatusUsecase,
          ),
        ),
      ],
      child: GetMaterialApp(
        title: 'SRSCS',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        getPages: [
          // Splash Screen
          GetPage(name: '/', page: () => const SplashScreen()),

          // Auth Routes
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(
            name: AppRoutes.register,
            page: () => const RegisterScreen(),
          ),
          GetPage(
            name: AppRoutes.forgotPassword,
            page: () => const ForgotPasswordScreen(),
          ),
          GetPage(
            name: AppRoutes.nidVerification,
            page: () => const NIDVerificationScreen(),
          ),

          // Citizen Routes
          GetPage(
            name: AppRoutes.citizenDashboard,
            page: () => const DashboardScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.submitComplaint,
            page: () => const SubmitComplaintScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.trackComplaints,
            page: () => const ComplaintTrackingScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.citizenChat,
            page: () => const ChatScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.profile,
            page: () => const ProfileScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),

          // Contractor Routes
          GetPage(
            name: AppRoutes.contractorDashboard,
            page: () => const ContractorDashboardScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.contractorTasks,
            page: () => const ContractorTasksScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.contractorTaskDetail,
            page: () => const ContractorTaskDetailScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.contractorCompleted,
            page: () => const ContractorCompletedTasksScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.contractorChat,
            page: () => const ChatScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.contractorProfile,
            page: () => const ProfileScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),

          // Admin Routes
          GetPage(
            name: AppRoutes.adminDashboard,
            page: () => const AdminDashboardScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminComplaints,
            page: () => const AdminComplaintsScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminComplaintDetail,
            page: () => const AdminComplaintDetailScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminAssignment,
            page: () => const AdminAssignmentScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminContractors,
            page: () => const AdminContractorsScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminContractorDetail,
            page: () => const AdminContractorDetailScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminContractorCreate,
            page: () => const AdminCreateContractorScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminChatManagement,
            page: () => const AdminChatListScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
          GetPage(
            name: AppRoutes.adminSettings,
            page: () => const AdminSettingsScreen(),
            middlewares: [RouteGuardMiddleware()],
          ),
        ],
        onUnknownRoute: (settings) {
          return GetPageRoute(
            page: () => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: const Center(
                child: Text('404 - Page Not Found'),
              ),
            ),
          );
        },
      ),
    );
  }
}
