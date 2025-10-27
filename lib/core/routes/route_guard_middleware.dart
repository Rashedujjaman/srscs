import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_routes.dart';
// import 'route_manager.dart';

/// Route Guard Middleware for GetX
///
/// Protects routes requiring authentication and role-based access
class RouteGuardMiddleware extends GetMiddleware {
  // final RouteManager _routeManager = RouteManager();

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not authenticated, redirect to login
      return const RouteSettings(name: AppRoutes.login);
    }

    // Check role-based access (synchronous check, will redirect on the route itself if needed)
    // The actual role checking happens in the screens via RouteManager

    return null; // Allow navigation, role check happens in screen
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    return page;
  }

  @override
  Widget onPageBuilt(Widget page) {
    return page;
  }

  @override
  void onPageDispose() {
    // Cleanup if needed
  }
}
