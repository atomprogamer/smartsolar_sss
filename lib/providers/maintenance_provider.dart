import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_model.dart';

/// Provider class for managing maintenance requests
class MaintenanceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<MaintenanceRequestModel> _userRequests = [];
  bool _isLoading = false;
  String? _error;
  
  /// Get user maintenance requests
  List<MaintenanceRequestModel> get userRequests => _userRequests;
  
  /// Get pending requests
  List<MaintenanceRequestModel> get pendingRequests => _userRequests.where((request) => 
      request.isPending).toList();
  
  /// Get assigned requests
  List<MaintenanceRequestModel> get assignedRequests => _userRequests.where((request) => 
      request.isAssigned).toList();
  
  /// Get in-progress requests
  List<MaintenanceRequestModel> get inProgressRequests => _userRequests.where((request) => 
      request.isInProgress).toList();
  
  /// Get completed requests
  List<MaintenanceRequestModel> get completedRequests => _userRequests.where((request) => 
      request.isCompleted).toList();
  
  /// Get cancelled requests
  List<MaintenanceRequestModel> get cancelledRequests => _userRequests.where((request) => 
      request.isCancelled).toList();
  
  /// Check if loading
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get error => _error;
  
  /// Fetch user maintenance requests
  Future<void> fetchUserRequests() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final requestsSnapshot = await _firestore.collection('maintenanceRequests')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('requestDate', descending: true)
          .get();
      
      _userRequests = requestsSnapshot.docs.map((doc) => MaintenanceRequestModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Fetch all maintenance requests (admin only)
  Future<List<MaintenanceRequestModel>> fetchAllRequests() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final requestsSnapshot = await _firestore.collection('maintenanceRequests')
          .orderBy('requestDate', descending: true)
          .get();
      
      final allRequests = requestsSnapshot.docs.map((doc) => MaintenanceRequestModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return allRequests;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return [];
    }
  }
  
  /// Fetch maintenance requests by status (admin only)
  Future<List<MaintenanceRequestModel>> fetchRequestsByStatus(String status) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final requestsSnapshot = await _firestore.collection('maintenanceRequests')
          .where('status', isEqualTo: status)
          .orderBy('requestDate', descending: true)
          .get();
      
      final statusRequests = requestsSnapshot.docs.map((doc) => MaintenanceRequestModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return statusRequests;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return [];
    }
  }
  
  /// Fetch maintenance requests by technician (technician only)
  Future<List<MaintenanceRequestModel>> fetchRequestsByTechnician(String technicianId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final requestsSnapshot = await _firestore.collection('maintenanceRequests')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .orderBy('requestDate', descending: true)
          .get();
      
      final technicianRequests = requestsSnapshot.docs.map((doc) => MaintenanceRequestModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return technicianRequests;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return [];
    }
  }
  
  /// Get maintenance request by ID
  Future<MaintenanceRequestModel?> getRequestById(String requestId) async {
    try {
      // First check if the request is already in the local list
      final localRequest = _userRequests.firstWhere(
        (request) => request.id == requestId,
        orElse: () => MaintenanceRequestModel.empty(),
      );
      
      if (localRequest.id.isNotEmpty) {
        return localRequest;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final requestDoc = await _firestore.collection('maintenanceRequests').doc(requestId).get();
      
      _isLoading = false;
      notifyListeners();
      
      if (!requestDoc.exists) {
        return null;
      }
      
      return MaintenanceRequestModel.fromSnapshot(requestDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return null;
    }
  }
  
  /// Submit maintenance request
  Future<bool> submitMaintenanceRequest({
    required String issueDescription,
    String? serviceId,
    required String address,
    String? city,
    GeoPoint? location,
    List<String>? imageUrls,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final requestRef = _firestore.collection('maintenanceRequests').doc();
      
      final newRequest = MaintenanceRequestModel(
        id: requestRef.id,
        userId: _auth.currentUser!.uid,
        serviceId: serviceId,
        issueDescription: issueDescription,
        requestDate: DateTime.now(),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        address: address,
        city: city,
        location: location,
        imageUrls: imageUrls,
      );
      
      await requestRef.set(newRequest.toMap());
      
      // Add to local list
      _userRequests.add(newRequest);
      
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
  
  /// Cancel maintenance request
  Future<bool> cancelRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          status: 'cancelled',
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
  
  /// Update request status (admin/technician only)
  Future<bool> updateRequestStatus(String requestId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          status: status,
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
  
  /// Assign technician to request (admin only)
  Future<bool> assignTechnician(String requestId, String technicianId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'assignedTechnicianId': technicianId,
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          assignedTechnicianId: technicianId,
          status: 'assigned',
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
  
  /// Add technician notes (technician only)
  Future<bool> addTechnicianNotes(String requestId, String notes) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'technicianNotes': notes,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          technicianNotes: notes,
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
  
  /// Schedule maintenance (admin/technician only)
  Future<bool> scheduleRequest(String requestId, DateTime scheduledDate) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          scheduledDate: scheduledDate,
          status: 'assigned',
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
  
  /// Start maintenance work (technician only)
  Future<bool> startWork(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'status': 'in_progress',
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          status: 'in_progress',
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
  
  /// Complete maintenance work (technician only)
  Future<bool> completeWork(String requestId, String notes) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('maintenanceRequests').doc(requestId).update({
        'status': 'completed',
        'technicianNotes': notes,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list if it's a user request
      final index = _userRequests.indexWhere((request) => request.id == requestId);
      if (index != -1) {
        _userRequests[index] = _userRequests[index].copyWith(
          status: 'completed',
          technicianNotes: notes,
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
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}