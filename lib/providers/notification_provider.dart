import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

/// Provider class for managing notifications
class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<NotificationModel> _userNotifications = [];
  bool _isLoading = false;
  String? _error;
  
  /// Get user notifications
  List<NotificationModel> get userNotifications => _userNotifications;
  
  /// Get unread notifications
  List<NotificationModel> get unreadNotifications => _userNotifications.where((notification) => 
      !notification.isRead).toList();
  
  /// Get unread notifications count
  int get unreadCount => unreadNotifications.length;
  
  /// Check if loading
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get error => _error;
  
  /// Fetch user notifications
  Future<void> fetchUserNotifications() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final notificationsSnapshot = await _firestore.collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('sentDate', descending: true)
          .get();
      
      _userNotifications = notificationsSnapshot.docs.map((doc) => NotificationModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      // First check if the notification is already in the local list
      final localNotification = _userNotifications.firstWhere(
        (notification) => notification.id == notificationId,
        orElse: () => NotificationModel.empty(),
      );
      
      if (localNotification.id.isNotEmpty) {
        return localNotification;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final notificationDoc = await _firestore.collection('notifications').doc(notificationId).get();
      
      _isLoading = false;
      notifyListeners();
      
      if (!notificationDoc.exists) {
        return null;
      }
      
      return NotificationModel.fromSnapshot(notificationDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return null;
    }
  }
  
  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list
      final index = _userNotifications.indexWhere((notification) => notification.id == notificationId);
      if (index != -1) {
        _userNotifications[index] = _userNotifications[index].copyWith(
          isRead: true,
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
  
  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }
      
      _isLoading = true;
      notifyListeners();
      
      // Get all unread notifications
      final unreadNotificationsSnapshot = await _firestore.collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Use batch to update all notifications
      final batch = _firestore.batch();
      
      for (final doc in unreadNotificationsSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
      
      // Update local list
      for (int i = 0; i < _userNotifications.length; i++) {
        if (!_userNotifications[i].isRead) {
          _userNotifications[i] = _userNotifications[i].copyWith(
            isRead: true,
            updatedAt: DateTime.now(),
          );
        }
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
  
  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('notifications').doc(notificationId).delete();
      
      // Remove from local list
      _userNotifications.removeWhere((notification) => notification.id == notificationId);
      
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
  
  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }
      
      _isLoading = true;
      notifyListeners();
      
      // Get all user notifications
      final notificationsSnapshot = await _firestore.collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();
      
      // Use batch to delete all notifications
      final batch = _firestore.batch();
      
      for (final doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Clear local list
      _userNotifications.clear();
      
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
  
  /// Send notification (admin only)
  Future<bool> sendNotification({
    required String userId,
    required String message,
    required NotificationType type,
    String? title,
    String? relatedId,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final notificationRef = _firestore.collection('notifications').doc();
      
      final newNotification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        message: message,
        type: type,
        sentDate: DateTime.now(),
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        title: title,
        relatedId: relatedId,
        imageUrl: imageUrl,
      );
      
      await notificationRef.set(newNotification.toMap());
      
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
  
  /// Send notification to all users (admin only)
  Future<bool> sendNotificationToAll({
    required String message,
    required NotificationType type,
    String? title,
    String? relatedId,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Use batch to create notifications for all users
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        
        final newNotification = NotificationModel(
          id: notificationRef.id,
          userId: userDoc.id,
          message: message,
          type: type,
          sentDate: DateTime.now(),
          isRead: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          title: title,
          relatedId: relatedId,
          imageUrl: imageUrl,
        );
        
        batch.set(notificationRef, newNotification.toMap());
      }
      
      await batch.commit();
      
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
  
  /// Create order notification
  Future<bool> createOrderNotification(String userId, String orderId, String orderStatus) async {
    try {
      String message;
      String title;
      
      switch (orderStatus.toLowerCase()) {
        case 'pending':
          title = 'Order Placed';
          message = 'Your order has been placed successfully and is pending confirmation.';
          break;
        case 'processing':
          title = 'Order Processing';
          message = 'Your order is now being processed.';
          break;
        case 'shipped':
          title = 'Order Shipped';
          message = 'Your order has been shipped and is on its way to you.';
          break;
        case 'delivered':
          title = 'Order Delivered';
          message = 'Your order has been delivered. Thank you for shopping with us!';
          break;
        case 'completed':
          title = 'Order Completed';
          message = 'Your order has been completed. We hope you enjoy your purchase!';
          break;
        case 'cancelled':
          title = 'Order Cancelled';
          message = 'Your order has been cancelled.';
          break;
        default:
          title = 'Order Update';
          message = 'There is an update to your order.';
      }
      
      return await sendNotification(
        userId: userId,
        message: message,
        type: NotificationType.order,
        title: title,
        relatedId: orderId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  /// Create service notification
  Future<bool> createServiceNotification(String userId, String serviceId, String serviceStatus) async {
    try {
      String message;
      String title;
      
      switch (serviceStatus.toLowerCase()) {
        case 'pending':
          title = 'Service Booking Received';
          message = 'Your service booking has been received and is pending confirmation.';
          break;
        case 'confirmed':
          title = 'Service Booking Confirmed';
          message = 'Your service booking has been confirmed.';
          break;
        case 'completed':
          title = 'Service Completed';
          message = 'Your service has been completed. Thank you for choosing our services!';
          break;
        case 'cancelled':
          title = 'Service Cancelled';
          message = 'Your service booking has been cancelled.';
          break;
        default:
          title = 'Service Update';
          message = 'There is an update to your service booking.';
      }
      
      return await sendNotification(
        userId: userId,
        message: message,
        type: NotificationType.service,
        title: title,
        relatedId: serviceId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  /// Create maintenance notification
  Future<bool> createMaintenanceNotification(String userId, String requestId, String requestStatus) async {
    try {
      String message;
      String title;
      
      switch (requestStatus.toLowerCase()) {
        case 'pending':
          title = 'Maintenance Request Received';
          message = 'Your maintenance request has been received and is pending assignment.';
          break;
        case 'assigned':
          title = 'Technician Assigned';
          message = 'A technician has been assigned to your maintenance request.';
          break;
        case 'in_progress':
          title = 'Maintenance In Progress';
          message = 'Your maintenance work is now in progress.';
          break;
        case 'completed':
          title = 'Maintenance Completed';
          message = 'Your maintenance work has been completed. Thank you for choosing our services!';
          break;
        case 'cancelled':
          title = 'Maintenance Cancelled';
          message = 'Your maintenance request has been cancelled.';
          break;
        default:
          title = 'Maintenance Update';
          message = 'There is an update to your maintenance request.';
      }
      
      return await sendNotification(
        userId: userId,
        message: message,
        type: NotificationType.maintenance,
        title: title,
        relatedId: requestId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  /// Create approval notification
  Future<bool> createApprovalNotification(String userId, bool isApproved) async {
    try {
      String message;
      String title;
      
      if (isApproved) {
        title = 'Account Approved';
        message = 'Your account has been approved. You can now log in and use all features of the app.';
      } else {
        title = 'Account Rejected';
        message = 'Your account registration has been rejected. Please contact support for more information.';
      }
      
      return await sendNotification(
        userId: userId,
        message: message,
        type: NotificationType.approval,
        title: title,
      );
    } catch (e) {
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