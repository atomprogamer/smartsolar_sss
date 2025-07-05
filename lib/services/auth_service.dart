import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Service class for handling authentication
/// Provides comprehensive authentication services for Smart Solar Solution app
/// Supports email/password and Google sign-in with user approval workflow
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Fixed: Proper GoogleSignIn initialization for version 6.1.5
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final SharedPreferences _prefs;

  /// Constructor requiring SharedPreferences instance
  AuthService(this._prefs);

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is currently logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  /// Returns UserModel if successful, null if failed
  /// Throws exception if user is not approved or not found
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return null;
      }

      // Check if user is approved and exists in database
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User not found in database');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final approvalStatus = userData['approvalStatus'] ?? 'pending';

      if (approvalStatus != 'approved') {
        await _auth.signOut();
        throw Exception('User account is not approved yet');
      }

      // Save user type to shared preferences for app-wide access
      await _saveUserTypeToPrefs(userData['userType'] ?? 'customer');

      return UserModel.fromSnapshot(userDoc);
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }

  /// Sign in with Google account
  /// Creates new user if doesn't exist, otherwise validates approval status
  /// Returns UserModel if successful, throws exception if not approved
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Fixed: Trigger the Google Sign-In flow with proper API
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled the sign-in process
      }

      // Fixed: Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Fixed: Create a new credential using the Google Sign-In tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google UserCredential
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user == null) {
        return null;
      }

      // Check if user exists in Firestore database
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user in Firestore with pending approval status
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
          profilePicture: user.photoURL,
          userType: UserType.customer,
          approvalStatus: ApprovalStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Sign out since user needs approval
        await _auth.signOut();
        throw Exception('Your account has been registered and is pending approval');
      } else {
        // Check if existing user is approved
        final userData = userDoc.data() as Map<String, dynamic>;
        final approvalStatus = userData['approvalStatus'] ?? 'pending';

        if (approvalStatus != 'approved') {
          await _auth.signOut();
          throw Exception('User account is not approved yet');
        }

        // Save user type to shared preferences
        await _saveUserTypeToPrefs(userData['userType'] ?? 'customer');

        return UserModel.fromSnapshot(userDoc);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Register new customer with email and password
  /// Creates user account with pending approval status
  /// Returns UserModel after successful registration
  Future<UserModel?> registerCustomer({
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
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return null;
      }

      // Create user profile in Firestore
      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        userType: userType,
        approvalStatus: ApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        city: city,
        location: location,
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // Sign out since user needs approval before accessing the app
      await _auth.signOut();

      return newUser;
    } catch (e) {
      print('Error registering customer: $e');
      rethrow;
    }
  }

  /// Register new staff member (expert, technician, admin)
  /// Creates user account with pending approval status
  /// Includes specialization field for experts and technicians
  Future<UserModel?> registerStaff({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserType userType,
    String? specialization,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return null;
      }

      // Create staff user profile in Firestore
      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        userType: userType,
        approvalStatus: ApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userData = newUser.toMap();

      // Add specialization for experts and technicians
      if (specialization != null && (userType == UserType.expert || userType == UserType.technician)) {
        userData['specialization'] = specialization;
      }

      await _firestore.collection('users').doc(user.uid).set(userData);

      // Sign out since staff needs approval before accessing the app
      await _auth.signOut();

      return newUser;
    } catch (e) {
      print('Error registering staff: $e');
      rethrow;
    }
  }

  /// Sign out current user from all services
  /// Clears Google sign-in session and user preferences
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _clearUserPrefs();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Send password reset email to user
  /// Used for password recovery functionality
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  /// Get current user data from Firestore
  /// Returns UserModel if user exists, null otherwise
  Future<UserModel?> getUserData() async {
    try {
      if (_auth.currentUser == null) {
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromSnapshot(userDoc);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user profile information
  /// Updates specified fields and maintains updatedAt timestamp
  Future<UserModel?> updateUserProfile({
    required String name,
    required String phoneNumber,
    String? address,
    String? profilePicture,
    String? city,
    GeoPoint? location,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return null;
      }

      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return null;
      }

      // Prepare update data with required fields
      final updatedData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.now(),
      };

      // Add optional fields if provided
      if (address != null) {
        updatedData['address'] = address;
      }

      if (profilePicture != null) {
        updatedData['profilePicture'] = profilePicture;
      }

      if (city != null) {
        updatedData['city'] = city;
      }

      if (location != null) {
        updatedData['location'] = location;
      }

      await userRef.update(updatedData);

      // Return updated user model
      final updatedUserDoc = await userRef.get();
      return UserModel.fromSnapshot(updatedUserDoc);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Save user type to shared preferences for app-wide access
  Future<void> _saveUserTypeToPrefs(String userType) async {
    try {
      await _prefs.setString('userType', userType);
    } catch (e) {
      print('Error saving user type to preferences: $e');
    }
  }

  /// Clear all user-related preferences
  Future<void> _clearUserPrefs() async {
    try {
      await _prefs.remove('userType');
    } catch (e) {
      print('Error clearing user preferences: $e');
    }
  }

  /// Get user type from shared preferences
  String? getUserTypeFromPrefs() {
    try {
      return _prefs.getString('userType');
    } catch (e) {
      print('Error getting user type from preferences: $e');
      return null;
    }
  }

  /// Check if current user is admin
  bool isAdmin() {
    final userType = getUserTypeFromPrefs();
    return userType == 'admin';
  }

  /// Check if current user is expert
  bool isExpert() {
    final userType = getUserTypeFromPrefs();
    return userType == 'expert';
  }

  /// Check if current user is technician
  bool isTechnician() {
    final userType = getUserTypeFromPrefs();
    return userType == 'technician';
  }

  /// Check if current user is staff (admin, expert, or technician)
  bool isStaff() {
    return isAdmin() || isExpert() || isTechnician();
  }

  /// Check if current user is customer
  bool isCustomer() {
    final userType = getUserTypeFromPrefs();
    return userType == 'customer';
  }

  /// Check if current user is vendor
  bool isVendor() {
    final userType = getUserTypeFromPrefs();
    return userType == 'vendor';
  }
}
