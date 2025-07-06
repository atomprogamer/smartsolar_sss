import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import '../models/user_model.dart';

/// Provider class for managing user data
class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  // User count cache
  int _totalUserCount = 0;
  int _pendingUserCount = 0;
  int _approvedUserCount = 0;
  int _rejectedUserCount = 0;

  // Cache timestamp
  DateTime? _lastCacheUpdate;

  /// Get current user
  UserModel? get currentUser => _currentUser;

  /// Get all users
  List<UserModel> get users => _users;

  /// Get pending approval users
  List<UserModel> get pendingApprovalUsers => _users.where((user) => 
      user.approvalStatus == ApprovalStatus.pending).toList();

  /// Alias for pendingApprovalUsers
  List<UserModel> get pendingUsers => pendingApprovalUsers;

  /// Get approved users
  List<UserModel> get approvedUsers => _users.where((user) => 
      user.approvalStatus == ApprovalStatus.approved).toList();

  /// Get customer users
  List<UserModel> get customerUsers => _users.where((user) => 
      user.userType == UserType.customer).toList();

  /// Get vendor users
  List<UserModel> get vendorUsers => _users.where((user) => 
      user.userType == UserType.vendor).toList();

  /// Get admin users
  List<UserModel> get adminUsers => _users.where((user) => 
      user.userType == UserType.admin).toList();

  /// Get expert users
  List<UserModel> get expertUsers => _users.where((user) => 
      user.userType == UserType.expert).toList();

  /// Get technician users
  List<UserModel> get technicianUsers => _users.where((user) => 
      user.userType == UserType.technician).toList();

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Get total user count
  int get totalUserCount => _totalUserCount;

  /// Get pending user count
  int get pendingUserCount => _pendingUserCount;

  /// Get approved user count
  int get approvedUserCount => _approvedUserCount;

  /// Get rejected user count
  int get rejectedUserCount => _rejectedUserCount;

  /// Check if cache is valid (less than 5 minutes old)
  bool get isCacheValid => _lastCacheUpdate != null && 
      DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5;

  /// Fetch current user data
  Future<void> fetchCurrentUser() async {
    try {
      if (_auth.currentUser == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }

      _isLoading = true;
      notifyListeners();

      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

      if (!userDoc.exists) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentUser = UserModel.fromSnapshot(userDoc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch all users (admin only)
  Future<void> fetchAllUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final usersSnapshot = await _firestore.collection('users').get();

      _users = usersSnapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();

      // Update local counts based on the fetched users
      _totalUserCount = _users.length;
      _pendingUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.pending).length;
      _approvedUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.approved).length;
      _rejectedUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.rejected).length;
      _lastCacheUpdate = DateTime.now();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error fetching all users: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Approve user (admin only)
  Future<bool> approveUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'approvalStatus': 'approved',
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _users.indexWhere((user) => user.uid == userId);
      if (index != -1) {
        // Check if the user was previously pending
        final wasPending = _users[index].approvalStatus == ApprovalStatus.pending;

        // Update the user in the local list
        _users[index] = _users[index].copyWith(
          approvalStatus: ApprovalStatus.approved,
          updatedAt: DateTime.now(),
        );

        // Update counts if the user was previously pending
        if (wasPending) {
          _pendingUserCount = math.max(0, _pendingUserCount - 1);
          _approvedUserCount++;
          _lastCacheUpdate = DateTime.now();
        }
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error approving user: ${e.toString()}';
      notifyListeners();

      return false;
    }
  }

  /// Reject user (admin only)
  Future<bool> rejectUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'approvalStatus': 'rejected',
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _users.indexWhere((user) => user.uid == userId);
      if (index != -1) {
        // Check if the user was previously pending
        final wasPending = _users[index].approvalStatus == ApprovalStatus.pending;

        // Update the user in the local list
        _users[index] = _users[index].copyWith(
          approvalStatus: ApprovalStatus.rejected,
          updatedAt: DateTime.now(),
        );

        // Update counts if the user was previously pending
        if (wasPending) {
          _pendingUserCount = math.max(0, _pendingUserCount - 1);
          _rejectedUserCount++;
          _lastCacheUpdate = DateTime.now();
        }
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error rejecting user: ${e.toString()}';
      notifyListeners();

      return false;
    }
  }

  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, UserType userType) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'userType': userType.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _users.indexWhere((user) => user.uid == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          userType: userType,
          updatedAt: DateTime.now(),
        );
      }

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
    required String userId,
    required String name,
    required String phoneNumber,
    String? address,
    String? city,
    GeoPoint? location,
    String? preferredSystemConfig,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updateData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.now(),
      };

      if (address != null) {
        updateData['address'] = address;
      }

      if (city != null) {
        updateData['city'] = city;
      }

      if (location != null) {
        updateData['location'] = location;
      }

      if (preferredSystemConfig != null) {
        updateData['preferredSystemConfig'] = preferredSystemConfig;
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      // Update local user if it's the current user
      if (_currentUser != null && _currentUser!.uid == userId) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        _currentUser = UserModel.fromSnapshot(userDoc);
      }

      // Update local list
      final index = _users.indexWhere((user) => user.uid == userId);
      if (index != -1) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        _users[index] = UserModel.fromSnapshot(userDoc);
      }

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

  /// Update user profile picture
  Future<bool> updateProfilePicture(String userId, String profilePictureUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'profilePicture': profilePictureUrl,
        'updatedAt': Timestamp.now(),
      });

      // Update local user if it's the current user
      if (_currentUser != null && _currentUser!.uid == userId) {
        _currentUser = _currentUser!.copyWith(
          profilePicture: profilePictureUrl,
          updatedAt: DateTime.now(),
        );
      }

      // Update local list
      final index = _users.indexWhere((user) => user.uid == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          profilePicture: profilePictureUrl,
          updatedAt: DateTime.now(),
        );
      }

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

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userDoc = await _firestore.collection('users').doc(userId).get();

      _isLoading = false;
      notifyListeners();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromSnapshot(userDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      final queryLower = query.toLowerCase();

      // First try to fetch from local list
      if (_users.isNotEmpty) {
        final results = _users.where((user) => 
            user.name.toLowerCase().contains(queryLower) || 
            user.email.toLowerCase().contains(queryLower)).toList();

        _isLoading = false;
        notifyListeners();

        return results;
      }

      // If local list is empty, fetch from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      final allUsers = usersSnapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();

      final results = allUsers.where((user) => 
          user.name.toLowerCase().contains(queryLower) || 
          user.email.toLowerCase().contains(queryLower)).toList();

      _isLoading = false;
      notifyListeners();

      return results;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch pending users (admin only)
  Future<void> fetchPendingUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final usersSnapshot = await _firestore.collection('users')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      final pendingUsers = usersSnapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();

      // Update the users list with pending users
      // First remove any existing pending users
      _users.removeWhere((user) => user.approvalStatus == ApprovalStatus.pending);
      // Then add the new pending users
      _users.addAll(pendingUsers);

      // Update pending users count
      _pendingUserCount = pendingUsers.length;

      // If we don't have a valid cache, fetch all counts
      if (!isCacheValid) {
        await fetchUserCounts();
      } else {
        // Otherwise just update the pending count and timestamp
        _lastCacheUpdate = DateTime.now();
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error fetching pending users: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Fetch user counts directly from Firestore
  /// This method fetches accurate counts by querying each status separately
  Future<void> fetchUserCounts() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch all users in a single query to minimize database calls
      final usersSnapshot = await _firestore.collection('users').get();
      final allUsers = usersSnapshot.docs;

      // Calculate counts
      _totalUserCount = allUsers.length;

      // Count by approval status
      _pendingUserCount = allUsers.where((doc) => 
          (doc.data() as Map<String, dynamic>)['approvalStatus'] == 'pending').length;

      _approvedUserCount = allUsers.where((doc) => 
          (doc.data() as Map<String, dynamic>)['approvalStatus'] == 'approved').length;

      _rejectedUserCount = allUsers.where((doc) => 
          (doc.data() as Map<String, dynamic>)['approvalStatus'] == 'rejected').length;

      // Update cache timestamp
      _lastCacheUpdate = DateTime.now();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error fetching user counts: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Fallback method to fetch user counts by getting all users
  /// Used if the count() method is not available
  Future<void> _fetchUserCountsFallback() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch all users
      final usersSnapshot = await _firestore.collection('users').get();
      final allUsers = usersSnapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();

      // Calculate counts
      _totalUserCount = allUsers.length;
      _pendingUserCount = allUsers.where((user) => user.approvalStatus == ApprovalStatus.pending).length;
      _approvedUserCount = allUsers.where((user) => user.approvalStatus == ApprovalStatus.approved).length;
      _rejectedUserCount = allUsers.where((user) => user.approvalStatus == ApprovalStatus.rejected).length;

      // Update cache timestamp
      _lastCacheUpdate = DateTime.now();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error fetching user counts (fallback): ${e.toString()}';
      notifyListeners();
    }
  }

  /// Update local counts based on the current users list
  /// This is used when we already have the users loaded
  void _updateLocalCounts() {
    if (_users.isNotEmpty) {
      _totalUserCount = _users.length;
      _pendingUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.pending).length;
      _approvedUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.approved).length;
      _rejectedUserCount = _users.where((user) => user.approvalStatus == ApprovalStatus.rejected).length;
      _lastCacheUpdate = DateTime.now();
    }
  }
}
