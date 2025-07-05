import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider class for managing authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  /// Constructor
  AuthProvider(SharedPreferences prefs) : _authService = AuthService(prefs) {
    _initializeUser();
  }

  /// Get current user
  UserModel? get user => _user;

  /// Check if user is logged in
  bool get isLoggedIn => _user != null;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Check if user is admin
  bool get isAdmin => _authService.isAdmin();

  /// Check if user is expert
  bool get isExpert => _authService.isExpert();

  /// Check if user is technician
  bool get isTechnician => _authService.isTechnician();

  /// Check if user is staff (admin, expert, or technician)
  bool get isStaff => _authService.isStaff();

  /// Check if user is customer
  bool get isCustomer => _authService.isCustomer();

  /// Check if user is vendor
  bool get isVendor => _authService.isVendor();

  /// Initialize user from Firebase
  Future<void> _initializeUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.getUserData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sign in with email and password
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Sign in with Google
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithFacebook();

      _isLoading = false;
      notifyListeners();

      return _user != null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Register customer
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Register staff
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Reset password
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Update user profile
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
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.getUserData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Firebase is used for authentication and data storage, no baseUrl needed
