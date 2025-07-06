import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_model.dart';

/// Provider class for managing service data
class ServiceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ServiceModel> _services = [];
  List<ServiceBookingModel> _userBookings = [];
  List<ServiceBookingModel> _technicianBookings = [];
  bool _isLoading = false;
  String? _error;

  /// Get all services
  List<ServiceModel> get services => _services;

  /// Get installation services
  List<ServiceModel> get installationServices => _services.where((service) => 
      service.serviceType.toLowerCase() == 'installation').toList();

  /// Get maintenance services
  List<ServiceModel> get maintenanceServices => _services.where((service) => 
      service.serviceType.toLowerCase() == 'maintenance').toList();

  /// Get repair services
  List<ServiceModel> get repairServices => _services.where((service) => 
      service.serviceType.toLowerCase() == 'repair').toList();

  /// Get consultation services
  List<ServiceModel> get consultationServices => _services.where((service) => 
      service.serviceType.toLowerCase() == 'consultation').toList();

  /// Get cleaning services
  List<ServiceModel> get cleaningServices => _services.where((service) => 
      service.serviceType.toLowerCase() == 'cleaning').toList();

  /// Get user bookings
  List<ServiceBookingModel> get userBookings => _userBookings;

  /// Get pending bookings
  List<ServiceBookingModel> get pendingBookings => _userBookings.where((booking) => 
      booking.isPending).toList();

  /// Get confirmed bookings
  List<ServiceBookingModel> get confirmedBookings => _userBookings.where((booking) => 
      booking.isConfirmed).toList();

  /// Get completed bookings
  List<ServiceBookingModel> get completedBookings => _userBookings.where((booking) => 
      booking.isCompleted).toList();

  /// Get technician bookings (technician only)
  List<ServiceBookingModel> get technicianBookings => _technicianBookings;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Fetch all services
  Future<void> fetchServices() async {
    try {
      _isLoading = true;
      notifyListeners();

      final servicesSnapshot = await _firestore.collection('services').get();

      _services = servicesSnapshot.docs.map((doc) => ServiceModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch user bookings
  Future<void> fetchUserBookings() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      final bookingsSnapshot = await _firestore.collection('serviceBookings')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('scheduledDate', descending: true)
          .get();

      _userBookings = bookingsSnapshot.docs.map((doc) => ServiceBookingModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch all bookings (admin only)
  Future<List<ServiceBookingModel>> fetchAllBookings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final bookingsSnapshot = await _firestore.collection('serviceBookings')
          .orderBy('scheduledDate', descending: true)
          .get();

      final allBookings = bookingsSnapshot.docs.map((doc) => ServiceBookingModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();

      return allBookings;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch bookings by status (admin only)
  Future<List<ServiceBookingModel>> fetchBookingsByStatus(String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      final bookingsSnapshot = await _firestore.collection('serviceBookings')
          .where('status', isEqualTo: status)
          .orderBy('scheduledDate', descending: true)
          .get();

      final statusBookings = bookingsSnapshot.docs.map((doc) => ServiceBookingModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();

      return statusBookings;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch bookings by technician (technician only)
  Future<void> fetchBookingsByTechnician(String technicianId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final bookingsSnapshot = await _firestore.collection('serviceBookings')
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .orderBy('scheduledDate', descending: true)
          .get();

      _technicianBookings = bookingsSnapshot.docs.map((doc) => ServiceBookingModel.fromSnapshot(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get service by ID
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      // First check if the service is already in the local list
      final localService = _services.firstWhere(
        (service) => service.id == serviceId,
        orElse: () => ServiceModel.empty(),
      );

      if (localService.id.isNotEmpty) {
        return localService;
      }

      _isLoading = true;
      notifyListeners();

      final serviceDoc = await _firestore.collection('services').doc(serviceId).get();

      _isLoading = false;
      notifyListeners();

      if (!serviceDoc.exists) {
        return null;
      }

      return ServiceModel.fromSnapshot(serviceDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Get booking by ID
  Future<ServiceBookingModel?> getBookingById(String bookingId) async {
    try {
      // First check if the booking is already in the local list
      final localBooking = _userBookings.firstWhere(
        (booking) => booking.id == bookingId,
        orElse: () => ServiceBookingModel.empty(),
      );

      if (localBooking.id.isNotEmpty) {
        return localBooking;
      }

      _isLoading = true;
      notifyListeners();

      final bookingDoc = await _firestore.collection('serviceBookings').doc(bookingId).get();

      _isLoading = false;
      notifyListeners();

      if (!bookingDoc.exists) {
        return null;
      }

      return ServiceBookingModel.fromSnapshot(bookingDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Book a service
  Future<bool> bookService({
    required String serviceId,
    required DateTime scheduledDate,
    required String location,
    String? notes,
    GeoPoint? locationCoordinates,
    String? city,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      final bookingRef = _firestore.collection('serviceBookings').doc();

      final newBooking = ServiceBookingModel(
        id: bookingRef.id,
        userId: _auth.currentUser!.uid,
        serviceId: serviceId,
        bookingDate: DateTime.now(),
        scheduledDate: scheduledDate,
        location: location,
        status: 'pending',
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        locationCoordinates: locationCoordinates,
        city: city,
      );

      await bookingRef.set(newBooking.toMap());

      // Add to local list
      _userBookings.add(newBooking);

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

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('serviceBookings').doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _userBookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
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

  /// Update booking status (admin only)
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('serviceBookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // Update local list if it's a user booking
      final index = _userBookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
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

  /// Assign technician to booking (admin only)
  Future<bool> assignTechnician(String bookingId, String technicianId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('serviceBookings').doc(bookingId).update({
        'assignedTechnicianId': technicianId,
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });

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

  /// Add service (admin only)
  /// This method adds a new service to Firestore and the local list
  /// It checks if a service with the same type already exists to avoid duplication
  Future<bool> addService(ServiceModel service) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if a service with the same type already exists
      final existingServicesQuery = await _firestore.collection('services')
          .where('serviceType', isEqualTo: service.serviceType)
          .get();

      if (existingServicesQuery.docs.isNotEmpty) {
        _error = 'A service with this type already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a new document with a generated ID
      final docRef = _firestore.collection('services').doc();
      final newService = service.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to Firestore with error handling
      try {
        await docRef.set(newService.toMap());
      } catch (firestoreError) {
        _error = 'Failed to save service to database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add to local list
      _services.add(newService);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error adding service: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update service (admin only)
  /// This method updates an existing service in Firestore and the local list
  /// It ensures the service exists before updating and handles various exceptions
  Future<bool> updateService(ServiceModel service) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the service exists
      final docRef = _firestore.collection('services').doc(service.id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = 'Service not found. It may have been deleted.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if another service with the same type exists (but different ID)
      if (service.serviceType.isNotEmpty) {
        final existingServicesQuery = await _firestore.collection('services')
            .where('serviceType', isEqualTo: service.serviceType)
            .get();

        for (var doc in existingServicesQuery.docs) {
          if (doc.id != service.id) {
            _error = 'Another service with this type already exists';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      // Update the service with the latest timestamp
      final updatedService = service.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in Firestore with error handling
      try {
        await docRef.update(updatedService.toMap());
      } catch (firestoreError) {
        _error = 'Failed to update service in database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update local list
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = updatedService;
      } else {
        // If not in local list, add it
        _services.add(updatedService);
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating service: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete service (admin only)
  /// This method deletes a service from Firestore and the local list
  /// It ensures the service exists before deleting and handles various exceptions
  Future<bool> deleteService(String serviceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the service exists
      final docRef = _firestore.collection('services').doc(serviceId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = 'Service not found. It may have been already deleted.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if the service is referenced in any bookings
      try {
        final bookingsQuery = await _firestore.collection('serviceBookings')
            .where('serviceId', isEqualTo: serviceId)
            .limit(1)
            .get();

        if (bookingsQuery.docs.isNotEmpty) {
          _error = 'Cannot delete service because it is referenced in bookings. Consider updating it instead.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (bookingCheckError) {
        // If we can't check bookings, proceed with deletion but log the error
        print('Error checking bookings for service: $bookingCheckError');
      }

      // Delete from Firestore with error handling
      try {
        await docRef.delete();
      } catch (firestoreError) {
        _error = 'Failed to delete service from database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove from local list
      _services.removeWhere((service) => service.id == serviceId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error deleting service: ${e.toString()}';
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
