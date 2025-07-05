import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_model.dart';
import '../models/user_model.dart';

/// Provider class for managing reviews and ratings
class ReviewProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ReviewModel> _userReviews = [];
  final Map<String, List<ReviewModel>> _productReviews = {};
  final Map<String, List<ReviewModel>> _serviceReviews = {};
  bool _isLoading = false;
  String? _error;

  /// Get user reviews
  List<ReviewModel> get userReviews => _userReviews;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Fetch user reviews
  Future<void> fetchUserReviews() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      final reviewsSnapshot =
          await _firestore
              .collection('reviews')
              .where('userId', isEqualTo: _auth.currentUser!.uid)
              .orderBy('reviewDate', descending: true)
              .get();

      _userReviews =
          reviewsSnapshot.docs
              .map((doc) => ReviewModel.fromSnapshot(doc))
              .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch product reviews
  Future<List<ReviewModel>> fetchProductReviews(String productId) async {
    try {
      // Check if we already have the reviews for this product
      if (_productReviews.containsKey(productId)) {
        return _productReviews[productId]!;
      }

      _isLoading = true;
      notifyListeners();

      final reviewsSnapshot =
          await _firestore
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .orderBy('reviewDate', descending: true)
              .get();

      final reviews =
          reviewsSnapshot.docs
              .map((doc) => ReviewModel.fromSnapshot(doc))
              .toList();

      // Cache the reviews
      _productReviews[productId] = reviews;

      _isLoading = false;
      notifyListeners();

      return reviews;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Fetch service reviews
  Future<List<ReviewModel>> fetchServiceReviews(String serviceId) async {
    try {
      // Check if we already have the reviews for this service
      if (_serviceReviews.containsKey(serviceId)) {
        return _serviceReviews[serviceId]!;
      }

      _isLoading = true;
      notifyListeners();

      final reviewsSnapshot =
          await _firestore
              .collection('reviews')
              .where('serviceId', isEqualTo: serviceId)
              .orderBy('reviewDate', descending: true)
              .get();

      final reviews =
          reviewsSnapshot.docs
              .map((doc) => ReviewModel.fromSnapshot(doc))
              .toList();

      // Cache the reviews
      _serviceReviews[serviceId] = reviews;

      _isLoading = false;
      notifyListeners();

      return reviews;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Get review by ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      // First check if the review is already in the local list
      final localReview = _userReviews.firstWhere(
        (review) => review.id == reviewId,
        orElse: () => ReviewModel.empty(),
      );

      if (localReview.id.isNotEmpty) {
        return localReview;
      }

      _isLoading = true;
      notifyListeners();

      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();

      _isLoading = false;
      notifyListeners();

      if (!reviewDoc.exists) {
        return null;
      }

      return ReviewModel.fromSnapshot(reviewDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Check if user has reviewed a product
  Future<bool> hasUserReviewedProduct(String productId) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }

      // First check in local reviews
      final hasLocalReview = _userReviews.any(
        (review) => review.productId == productId,
      );

      if (hasLocalReview) {
        return true;
      }

      // Check in Firestore
      final reviewsSnapshot =
          await _firestore
              .collection('reviews')
              .where('userId', isEqualTo: _auth.currentUser!.uid)
              .where('productId', isEqualTo: productId)
              .limit(1)
              .get();

      return reviewsSnapshot.docs.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Check if user has reviewed a service
  Future<bool> hasUserReviewedService(String serviceId) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }

      // First check in local reviews
      final hasLocalReview = _userReviews.any(
        (review) => review.serviceId == serviceId,
      );

      if (hasLocalReview) {
        return true;
      }

      // Check in Firestore
      final reviewsSnapshot =
          await _firestore
              .collection('reviews')
              .where('userId', isEqualTo: _auth.currentUser!.uid)
              .where('serviceId', isEqualTo: serviceId)
              .limit(1)
              .get();

      return reviewsSnapshot.docs.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Submit product review
  Future<bool> submitProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      // Check if user has already reviewed this product
      final hasReviewed = await hasUserReviewedProduct(productId);
      if (hasReviewed) {
        _error = 'You have already reviewed this product';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      // Get user data for display name and image
      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
      final userData = userDoc.data();

      final reviewRef = _firestore.collection('reviews').doc();

      final newReview = ReviewModel(
        id: reviewRef.id,
        userId: _auth.currentUser!.uid,
        productId: productId,
        rating: rating,
        comment: comment,
        reviewDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userName: userData?['name'],
        userImage: userData?['profilePicture'],
      );

      await reviewRef.set(newReview.toMap());

      // Add to local lists
      _userReviews.add(newReview);

      if (_productReviews.containsKey(productId)) {
        _productReviews[productId]!.add(newReview);
      } else {
        _productReviews[productId] = [newReview];
      }

      // Update product average rating
      await _updateProductAverageRating(productId);

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

  /// Submit service review
  Future<bool> submitServiceReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      // Check if user has already reviewed this service
      final hasReviewed = await hasUserReviewedService(serviceId);
      if (hasReviewed) {
        _error = 'You have already reviewed this service';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      // Get user data for display name and image
      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
      final userData = userDoc.data();

      final reviewRef = _firestore.collection('reviews').doc();

      final newReview = ReviewModel(
        id: reviewRef.id,
        userId: _auth.currentUser!.uid,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
        reviewDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userName: userData?['name'],
        userImage: userData?['profilePicture'],
      );

      await reviewRef.set(newReview.toMap());

      // Add to local lists
      _userReviews.add(newReview);

      if (_serviceReviews.containsKey(serviceId)) {
        _serviceReviews[serviceId]!.add(newReview);
      } else {
        _serviceReviews[serviceId] = [newReview];
      }

      // Update service average rating
      await _updateServiceAverageRating(serviceId);

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

  /// Update product average rating
  Future<void> _updateProductAverageRating(String productId) async {
    try {
      final reviews = await fetchProductReviews(productId);

      if (reviews.isEmpty) {
        return;
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'reviewCount': reviews.length,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating product average rating: $e');
    }
  }

  /// Update service average rating
  Future<void> _updateServiceAverageRating(String serviceId) async {
    try {
      final reviews = await fetchServiceReviews(serviceId);

      if (reviews.isEmpty) {
        return;
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      await _firestore.collection('services').doc(serviceId).update({
        'averageRating': averageRating,
        'reviewCount': reviews.length,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating service average rating: $e');
    }
  }

  /// Delete review (user can delete their own reviews)
  Future<bool> deleteReview(String reviewId) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      // Get the review to check if it belongs to the user
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();

      if (!reviewDoc.exists) {
        _error = 'Review not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final reviewData = reviewDoc.data() as Map<String, dynamic>;

      if (reviewData['userId'] != _auth.currentUser!.uid) {
        _error = 'You can only delete your own reviews';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Store product/service ID before deleting
      final productId = reviewData['productId'] as String?;
      final serviceId = reviewData['serviceId'] as String?;

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Remove from local lists
      _userReviews.removeWhere((review) => review.id == reviewId);

      if (productId != null && _productReviews.containsKey(productId)) {
        _productReviews[productId]!.removeWhere(
          (review) => review.id == reviewId,
        );
        await _updateProductAverageRating(productId);
      }

      if (serviceId != null && _serviceReviews.containsKey(serviceId)) {
        _serviceReviews[serviceId]!.removeWhere(
          (review) => review.id == reviewId,
        );
        await _updateServiceAverageRating(serviceId);
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

  /// Get average rating for a product
  Future<double> getProductAverageRating(String productId) async {
    try {
      final reviews = await fetchProductReviews(productId);

      if (reviews.isEmpty) {
        return 0.0;
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      return totalRating / reviews.length;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return 0.0;
    }
  }

  /// Get average rating for a service
  Future<double> getServiceAverageRating(String serviceId) async {
    try {
      final reviews = await fetchServiceReviews(serviceId);

      if (reviews.isEmpty) {
        return 0.0;
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      return totalRating / reviews.length;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return 0.0;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
