import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../constants/user_roles.dart';

/// Provides role-based theme colors throughout the application
///
/// This provider fetches the user's role and provides appropriate colors
/// to ensure consistent theming across all screens based on user role.
class AppThemeProvider extends ChangeNotifier {
  Color _primaryColor =
      const Color.fromARGB(255, 0, 0, 0); // Default: Citizen purple
  UserRole? _userRole;
  bool _isLoading = false;

  /// Get the primary color based on user role
  Color get primaryColor => _primaryColor;

  /// Get the current user role
  UserRole? get userRole => _userRole;

  /// Check if theme is still loading
  bool get isLoading => _isLoading;

  /// Get lighter shade of primary color (for backgrounds)
  Color get primaryColorLight => _primaryColor.withValues(alpha: 0.1);

  /// Get darker shade of primary color (for hover states)
  Color get primaryColorDark => Color.lerp(_primaryColor, Colors.black, 0.2)!;

  /// Initialize theme by fetching user role
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setDefaultTheme();
        return;
      }

      final authService = AuthService();
      final role = await authService.getUserRole(user.uid);

      if (role != null) {
        _userRole = role;
        _primaryColor = role.color;
      } else {
        _setDefaultTheme();
      }
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      _setDefaultTheme();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set default theme (citizen)
  void _setDefaultTheme() {
    _userRole = UserRole.citizen;
    _primaryColor = UserRole.citizen.color;
  }

  /// Manually update theme based on role (useful after login)
  void setThemeForRole(UserRole role) {
    _userRole = role;
    _primaryColor = role.color;
    _isLoading = false;
    notifyListeners();
  }

  /// Reset theme to default
  void reset() {
    _setDefaultTheme();
    _isLoading = false;
    notifyListeners();
  }

  /// Get collection name based on role
  String get collectionName {
    if (_userRole == null) {
      // If role not set, return default
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return 'citizens';
      }
      return 'users';
    }

    switch (_userRole) {
      case UserRole.citizen:
        return 'citizens';
      case UserRole.contractor:
        return 'contractors';
      case UserRole.admin:
        return 'admins';
      default:
        return 'users';
    }
  }

  /// Check if current user is admin
  bool get isAdmin => _userRole?.isAdmin ?? false;

  /// Check if current user is contractor
  bool get isContractor => _userRole?.isContractor ?? false;

  /// Check if current user is citizen
  bool get isCitizen => _userRole?.isCitizen ?? false;
}
