import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Service class for handling authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final SharedPreferences _prefs;
  
  /// Constructor
  AuthService(this._prefs);
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign in with email and password
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
      
      // Check if user is approved
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
      
      // Save user type to shared preferences
      await _saveUserTypeToPrefs(userData['userType'] ?? 'customer');
      
      return UserModel.fromSnapshot(userDoc);
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) {
        return null;
      }
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create new user in Firestore
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
        // Check if user is approved
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
  
  /// Sign in with Facebook
  Future<UserModel?> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await _facebookAuth.login();
      
      if (loginResult.status != LoginStatus.success) {
        return null;
      }
      
      final OAuthCredential credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );
      
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) {
        return null;
      }
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create new user in Firestore
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
        // Check if user is approved
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
      print('Error signing in with Facebook: $e');
      rethrow;
    }
  }
  
  /// Register with email and password (customer)
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
      
      // Create user in Firestore
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
      
      // Sign out since user needs approval
      await _auth.signOut();
      
      return newUser;
    } catch (e) {
      print('Error registering customer: $e');
      rethrow;
    }
  }
  
  /// Register with email and password (staff)
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
      
      // Create user in Firestore
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
      
      // Sign out since user needs approval
      await _auth.signOut();
      
      return newUser;
    } catch (e) {
      print('Error registering staff: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _auth.signOut();
      await _clearUserPrefs();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }
  
  /// Get user data from Firestore
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
  
  /// Update user profile
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
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      final updatedData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.now(),
      };
      
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
      
      final updatedUserDoc = await userRef.get();
      return UserModel.fromSnapshot(updatedUserDoc);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  /// Save user type to shared preferences
  Future<void> _saveUserTypeToPrefs(String userType) async {
    await _prefs.setString('userType', userType);
  }
  
  /// Clear user preferences
  Future<void> _clearUserPrefs() async {
    await _prefs.remove('userType');
  }
  
  /// Get user type from shared preferences
  String? getUserTypeFromPrefs() {
    return _prefs.getString('userType');
  }
  
  /// Check if user is admin
  bool isAdmin() {
    final userType = getUserTypeFromPrefs();
    return userType == 'admin';
  }
  
  /// Check if user is expert
  bool isExpert() {
    final userType = getUserTypeFromPrefs();
    return userType == 'expert';
  }
  
  /// Check if user is technician
  bool isTechnician() {
    final userType = getUserTypeFromPrefs();
    return userType == 'technician';
  }
  
  /// Check if user is staff (admin, expert, or technician)
  bool isStaff() {
    return isAdmin() || isExpert() || isTechnician();
  }
  
  /// Check if user is customer
  bool isCustomer() {
    final userType = getUserTypeFromPrefs();
    return userType == 'customer';
  }
  
  /// Check if user is vendor
  bool isVendor() {
    final userType = getUserTypeFromPrefs();
    return userType == 'vendor';
  }
}