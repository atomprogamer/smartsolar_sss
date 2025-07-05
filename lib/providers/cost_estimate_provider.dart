import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cost_estimate_model.dart';
import '../models/product_model.dart';

/// Provider class for managing cost estimates
class CostEstimateProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<CostEstimateModel> _userEstimates = [];
  CostEstimateModel? _currentEstimate;
  List<RecommendedProductModel> _recommendedProducts = [];
  bool _isLoading = false;
  String? _error;
  
  /// Get user estimates
  List<CostEstimateModel> get userEstimates => _userEstimates;
  
  /// Get current estimate
  CostEstimateModel? get currentEstimate => _currentEstimate;
  
  /// Get recommended products
  List<RecommendedProductModel> get recommendedProducts => _recommendedProducts;
  
  /// Check if loading
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get error => _error;
  
  /// Fetch user estimates
  Future<void> fetchUserEstimates() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final estimatesSnapshot = await _firestore.collection('costEstimates')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<CostEstimateModel> estimates = [];
      
      for (final doc in estimatesSnapshot.docs) {
        final recommendedProductsSnapshot = await _firestore.collection('recommendedProducts')
            .where('estimateId', isEqualTo: doc.id)
            .get();
        
        final recommendedProducts = recommendedProductsSnapshot.docs
            .map((itemDoc) => RecommendedProductModel.fromMap(itemDoc.data()))
            .toList();
        
        estimates.add(CostEstimateModel.fromSnapshot(doc, products: recommendedProducts));
      }
      
      _userEstimates = estimates;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Get estimate by ID
  Future<CostEstimateModel?> getEstimateById(String estimateId) async {
    try {
      // First check if the estimate is already in the local list
      final localEstimate = _userEstimates.firstWhere(
        (estimate) => estimate.id == estimateId,
        orElse: () => CostEstimateModel.empty(),
      );
      
      if (localEstimate.id.isNotEmpty) {
        return localEstimate;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final estimateDoc = await _firestore.collection('costEstimates').doc(estimateId).get();
      
      if (!estimateDoc.exists) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      final recommendedProductsSnapshot = await _firestore.collection('recommendedProducts')
          .where('estimateId', isEqualTo: estimateId)
          .get();
      
      final recommendedProducts = recommendedProductsSnapshot.docs
          .map((itemDoc) => RecommendedProductModel.fromMap(itemDoc.data()))
          .toList();
      
      final estimate = CostEstimateModel.fromSnapshot(estimateDoc, products: recommendedProducts);
      
      _isLoading = false;
      notifyListeners();
      
      return estimate;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return null;
    }
  }
  
  /// Calculate cost estimate
  Future<void> calculateCostEstimate({
    required String energyRequirement,
    required String location,
    GeoPoint? locationCoordinates,
    String? city,
    String? notes,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      // Parse energy requirement to get a numeric value
      final energyValue = double.tryParse(
        energyRequirement.replaceAll(RegExp(r'[^0-9.]'), '')
      ) ?? 0.0;
      
      if (energyValue <= 0) {
        _error = 'Invalid energy requirement';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Calculate costs based on energy requirement
      // These are simplified calculations for demonstration purposes
      final equipmentCost = energyValue * 15000; // PKR per kW for equipment
      final installationCost = energyValue * 5000; // PKR per kW for installation
      final maintenanceCost = energyValue * 2000; // PKR per kW for annual maintenance
      final totalCost = equipmentCost + installationCost + maintenanceCost;
      
      // Generate recommended products
      await _generateRecommendedProducts(energyValue);
      
      // Create cost estimate
      final estimateRef = _firestore.collection('costEstimates').doc();
      
      final newEstimate = CostEstimateModel(
        id: estimateRef.id,
        userId: _auth.currentUser!.uid,
        energyRequirement: energyRequirement,
        location: location,
        totalCost: totalCost,
        equipmentCost: equipmentCost,
        installationCost: installationCost,
        maintenanceCost: maintenanceCost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        locationCoordinates: locationCoordinates,
        city: city,
        recommendedProducts: _recommendedProducts,
        notes: notes,
      );
      
      await estimateRef.set(newEstimate.toMap());
      
      // Save recommended products
      final batch = _firestore.batch();
      
      for (final product in _recommendedProducts) {
        final productRef = _firestore.collection('recommendedProducts').doc();
        
        final productData = {
          ...product.toMap(),
          'estimateId': estimateRef.id,
        };
        
        batch.set(productRef, productData);
      }
      
      await batch.commit();
      
      // Set current estimate
      _currentEstimate = newEstimate;
      
      // Add to local list
      _userEstimates.insert(0, newEstimate);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Generate recommended products based on energy requirement
  Future<void> _generateRecommendedProducts(double energyValue) async {
    try {
      _recommendedProducts = [];
      
      // Fetch solar panels
      final solarPanelsSnapshot = await _firestore.collection('products')
          .where('category', isEqualTo: 'solarPanel')
          .limit(2)
          .get();
      
      // Fetch batteries
      final batteriesSnapshot = await _firestore.collection('products')
          .where('category', isEqualTo: 'battery')
          .limit(2)
          .get();
      
      // Fetch inverters
      final invertersSnapshot = await _firestore.collection('products')
          .where('category', isEqualTo: 'inverter')
          .limit(1)
          .get();
      
      // Calculate quantities based on energy requirement
      final panelQuantity = (energyValue / 0.5).ceil(); // Assuming 500W panels
      final batteryQuantity = (energyValue / 2.4).ceil(); // Assuming 2.4kWh batteries
      final inverterQuantity = 1; // Usually one inverter per system
      
      // Add solar panels to recommended products
      for (final doc in solarPanelsSnapshot.docs) {
        final product = ProductModel.fromSnapshot(doc);
        
        _recommendedProducts.add(RecommendedProductModel(
          productId: product.id,
          productName: product.name,
          productCategory: product.categoryName,
          quantity: panelQuantity,
          price: product.price,
          imageUrl: product.mainImageUrl,
        ));
      }
      
      // Add batteries to recommended products
      for (final doc in batteriesSnapshot.docs) {
        final product = ProductModel.fromSnapshot(doc);
        
        _recommendedProducts.add(RecommendedProductModel(
          productId: product.id,
          productName: product.name,
          productCategory: product.categoryName,
          quantity: batteryQuantity,
          price: product.price,
          imageUrl: product.mainImageUrl,
        ));
      }
      
      // Add inverter to recommended products
      for (final doc in invertersSnapshot.docs) {
        final product = ProductModel.fromSnapshot(doc);
        
        _recommendedProducts.add(RecommendedProductModel(
          productId: product.id,
          productName: product.name,
          productCategory: product.categoryName,
          quantity: inverterQuantity,
          price: product.price,
          imageUrl: product.mainImageUrl,
        ));
      }
    } catch (e) {
      print('Error generating recommended products: $e');
      // Don't throw the error, just log it
    }
  }
  
  /// Delete estimate
  Future<bool> deleteEstimate(String estimateId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Delete recommended products first
      final recommendedProductsSnapshot = await _firestore.collection('recommendedProducts')
          .where('estimateId', isEqualTo: estimateId)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in recommendedProductsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Delete the estimate
      await _firestore.collection('costEstimates').doc(estimateId).delete();
      
      // Remove from local list
      _userEstimates.removeWhere((estimate) => estimate.id == estimateId);
      
      // Clear current estimate if it's the one being deleted
      if (_currentEstimate?.id == estimateId) {
        _currentEstimate = null;
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
  
  /// Update estimate notes
  Future<bool> updateEstimateNotes(String estimateId, String notes) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('costEstimates').doc(estimateId).update({
        'notes': notes,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list
      final index = _userEstimates.indexWhere((estimate) => estimate.id == estimateId);
      if (index != -1) {
        _userEstimates[index] = _userEstimates[index].copyWith(
          notes: notes,
          updatedAt: DateTime.now(),
        );
      }
      
      // Update current estimate if it's the one being updated
      if (_currentEstimate?.id == estimateId) {
        _currentEstimate = _currentEstimate!.copyWith(
          notes: notes,
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
  
  /// Add products from estimate to cart
  void addEstimateProductsToCart(Function(ProductModel, int) addToCartFunction) {
    try {
      if (_currentEstimate == null || _currentEstimate!.recommendedProducts == null) {
        _error = 'No current estimate or recommended products';
        notifyListeners();
        return;
      }
      
      for (final recommendedProduct in _currentEstimate!.recommendedProducts!) {
        // Create a temporary product model to add to cart
        final product = ProductModel(
          id: recommendedProduct.productId,
          name: recommendedProduct.productName,
          description: '',
          category: _getCategoryFromString(recommendedProduct.productCategory),
          brand: '',
          capacity: '',
          price: recommendedProduct.price,
          imageUrls: recommendedProduct.imageUrl != null ? [recommendedProduct.imageUrl!] : [],
          stockQuantity: 100, // Assuming sufficient stock
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Add to cart
        addToCartFunction(product, recommendedProduct.quantity);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Helper method to convert string to ProductCategory enum
  ProductCategory _getCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'solar panel':
        return ProductCategory.solarPanel;
      case 'battery':
        return ProductCategory.battery;
      case 'inverter':
        return ProductCategory.inverter;
      case 'stand':
        return ProductCategory.stand;
      case 'accessory':
        return ProductCategory.accessory;
      default:
        return ProductCategory.accessory;
    }
  }
  
  /// Clear current estimate
  void clearCurrentEstimate() {
    _currentEstimate = null;
    _recommendedProducts = [];
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}