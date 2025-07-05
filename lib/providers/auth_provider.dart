import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider class for managing authentication state
/// Provides comprehensive authentication state management for Smart Solar Solution app
/// Supports email/password and Google sign-in with user approval workflow
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  /// Constructor requiring SharedPreferences instance
  AuthProvider(SharedPreferences prefs) : _authService = AuthService(prefs) {
    _initializeUser();
  }

  /// Get current authenticated user
  UserModel? get user => _user;

  /// Check if user is currently logged in
  bool get isLoggedIn => _user != null;

  /// Check if authentication operation is in progress
  bool get isLoading => _isLoading;

  /// Get current error message if any
  String? get error => _error;

  /// Check if current user is admin
  bool get isAdmin => _authService.isAdmin();

  /// Check if current user is expert
  bool get isExpert => _authService.isExpert();

  /// Check if current user is technician
  bool get isTechnician => _authService.isTechnician();

  /// Check if current user is staff (admin, expert, or technician)
  bool get isStaff => _authService.isStaff();

  /// Check if current user is customer
  bool get isCustomer => _authService.isCustomer();

  /// Check if current user is vendor
  bool get isVendor => _authService.isVendor();

  /// Initialize user from Firebase authentication state
  /// Called automatically during provider initialization
  Future<void> _initializeUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.getUserData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to initialize user: ${e.toString()}';
      notifyListeners();
      print('Error initializing user: $e');
    }
  }

  /// Sign in with email and password
  /// Returns true if successful, false otherwise
  /// Sets error message if authentication fails
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithEmailAndPassword(email, password);

      _isLoading = false;
      notifyListeners();

      return _user != null;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error signing in with email and password: $e');

      return false;
    }
  }

  /// Sign in with Google account
  /// Returns true if successful, false otherwise
  /// Creates new user if doesn't exist, validates approval status
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithGoogle();

      _isLoading = false;
      notifyListeners();

      return _user != null;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error signing in with Google: $e');

      return false;
    }
  }

  /// Register new customer with email and password
  /// Creates user account with pending approval status
  /// Returns true if successful, false otherwise
  Future<bool> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String address,
    required UserType userType,
    String? city,
    GeoPoint? location,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerCustomer(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        userType: userType,
        city: city,
        location: location,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error registering customer: $e');

      return false;
    }
  }

  /// Register new staff member (expert, technician, admin)
  /// Creates user account with pending approval status
  /// Returns true if successful, false otherwise
  Future<bool> registerStaff({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserType userType,
    String? specialization,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerStaff(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        userType: userType,
        specialization: specialization,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error registering staff: $e');

      return false;
    }
  }

  /// Sign out current user from all services
  /// Clears user data and authentication state
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signOut();
      _user = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
      print('Error signing out: $e');
    }
  }

  /// Send password reset email to user
  /// Used for password recovery functionality
  /// Returns true if successful, false otherwise
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error resetting password: $e');

      return false;
    }
  }

  /// Update user profile information
  /// Updates specified fields and maintains updatedAt timestamp
  /// Returns true if successful, false otherwise
  Future<bool> updateUserProfile({
    required String name,
    required String phoneNumber,
    String? address,
    String? profilePicture,
    String? city,
    GeoPoint? location,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        profilePicture: profilePicture,
        city: city,
        location: location,
      );

      _isLoading = false;
      notifyListeners();

      return _user != null;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e.toString());
      notifyListeners();
      print('Error updating user profile: $e');

      return false;
    }
  }

  /// Refresh user data from Firestore
  /// Useful for updating user information after external changes
  Future<void> refreshUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.getUserData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to refresh user data: ${e.toString()}';
      notifyListeners();
      print('Error refreshing user: $e');
    }
  }

  /// Clear current error message
  /// Used to reset error state after displaying error to user
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Format error messages for user-friendly display
  /// Converts technical error messages to readable format
  String _formatErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again';
    } else if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email address';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('pending approval')) {
      return 'Your account is pending approval. Please wait for admin approval';
    } else if (error.contains('not approved')) {
      return 'Your account is not approved yet. Please contact support';
    } else {
      return error.replaceAll('Exception: ', '');
    }
  }

  /// Check if user has specific permissions based on user type
  /// Used for role-based access control throughout the app
  bool hasPermission(String permission) {
    switch (permission) {
      case 'manage_orders':
        return isAdmin || isStaff;
      case 'manage_products':
        return isAdmin;
      case 'view_analytics':
        return isAdmin || isExpert;
      case 'manage_services':
        return isAdmin || isTechnician || isExpert;
      case 'view_customer_data':
        return isStaff;
      default:
        return false;
    }
  }
}

// Firebase is used for authentication and data storage, no baseUrl needed
