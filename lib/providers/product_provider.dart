import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

/// Provider class for managing product data
class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = false;
  String? _error;
  
  /// Get all products
  List<ProductModel> get products => _products;
  
  /// Get featured products
  List<ProductModel> get featuredProducts => _featuredProducts;
  
  /// Get solar panel products
  List<ProductModel> get solarPanels => _products.where((product) => 
      product.category == ProductCategory.solarPanel).toList();
  
  /// Get battery products
  List<ProductModel> get batteries => _products.where((product) => 
      product.category == ProductCategory.battery).toList();
  
  /// Get inverter products
  List<ProductModel> get inverters => _products.where((product) => 
      product.category == ProductCategory.inverter).toList();
  
  /// Get stand products
  List<ProductModel> get stands => _products.where((product) => 
      product.category == ProductCategory.stand).toList();
  
  /// Get accessory products
  List<ProductModel> get accessories => _products.where((product) => 
      product.category == ProductCategory.accessory).toList();
  
  /// Get in-stock products
  List<ProductModel> get inStockProducts => _products.where((product) => 
      product.stockQuantity > 0).toList();
  
  /// Check if loading
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get error => _error;
  
  /// Fetch all products
  Future<void> fetchProducts() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final productsSnapshot = await _firestore.collection('products').get();
      
      _products = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Fetch featured products
  Future<void> fetchFeaturedProducts() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final productsSnapshot = await _firestore.collection('products')
          .where('featured', isEqualTo: true)
          .limit(10)
          .get();
      
      _featuredProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Fetch products by category
  Future<List<ProductModel>> fetchProductsByCategory(ProductCategory category) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final categoryString = category.toString().split('.').last;
      
      final productsSnapshot = await _firestore.collection('products')
          .where('category', isEqualTo: categoryString)
          .get();
      
      final categoryProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return categoryProducts;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return [];
    }
  }
  
  /// Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      // First check if the product is already in the local list
      final localProduct = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => ProductModel.empty(),
      );
      
      if (localProduct.id.isNotEmpty) {
        return localProduct;
      }
      
      _isLoading = true;
      notifyListeners();
      
      final productDoc = await _firestore.collection('products').doc(productId).get();
      
      _isLoading = false;
      notifyListeners();
      
      if (!productDoc.exists) {
        return null;
      }
      
      return ProductModel.fromSnapshot(productDoc);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return null;
    }
  }
  
  /// Search products by name or description
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final queryLower = query.toLowerCase();
      
      // First try to fetch from local list
      if (_products.isNotEmpty) {
        final results = _products.where((product) => 
            product.name.toLowerCase().contains(queryLower) || 
            product.description.toLowerCase().contains(queryLower)).toList();
        
        _isLoading = false;
        notifyListeners();
        
        return results;
      }
      
      // If local list is empty, fetch from Firestore
      final productsSnapshot = await _firestore.collection('products').get();
      final allProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
      
      final results = allProducts.where((product) => 
          product.name.toLowerCase().contains(queryLower) || 
          product.description.toLowerCase().contains(queryLower)).toList();
      
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
  
  /// Filter products by price range
  List<ProductModel> filterByPriceRange(double minPrice, double maxPrice) {
    return _products.where((product) => 
        product.price >= minPrice && product.price <= maxPrice).toList();
  }
  
  /// Filter products by brand
  List<ProductModel> filterByBrand(String brand) {
    return _products.where((product) => 
        product.brand.toLowerCase() == brand.toLowerCase()).toList();
  }
  
  /// Filter products by capacity
  List<ProductModel> filterByCapacity(String capacity) {
    return _products.where((product) => 
        product.capacity.toLowerCase() == capacity.toLowerCase()).toList();
  }
  
  /// Get all available brands
  List<String> get availableBrands {
    final brands = _products.map((product) => product.brand).toSet().toList();
    brands.sort();
    return brands;
  }
  
  /// Get all available capacities
  List<String> get availableCapacities {
    final capacities = _products.map((product) => product.capacity).toSet().toList();
    capacities.sort();
    return capacities;
  }
  
  /// Add product (admin only)
  Future<bool> addProduct(ProductModel product) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final docRef = _firestore.collection('products').doc();
      final newProduct = product.copyWith(id: docRef.id);
      
      await docRef.set(newProduct.toMap());
      
      // Add to local list
      _products.add(newProduct);
      
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
  
  /// Update product (admin only)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('products').doc(product.id).update(product.toMap());
      
      // Update local list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
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
  
  /// Delete product (admin only)
  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('products').doc(productId).delete();
      
      // Remove from local list
      _products.removeWhere((product) => product.id == productId);
      
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
  
  /// Update product stock (admin only)
  Future<bool> updateProductStock(String productId, int newStockQuantity) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('products').doc(productId).update({
        'stockQuantity': newStockQuantity,
        'updatedAt': Timestamp.now(),
      });
      
      // Update local list
      final index = _products.indexWhere((product) => product.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stockQuantity: newStockQuantity,
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
  
  /// Get recommended products based on energy requirement
  List<ProductModel> getRecommendedProducts(String energyRequirement) {
    // This is a simplified recommendation logic
    // In a real app, this would be more sophisticated
    
    final energyValue = double.tryParse(energyRequirement.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    if (energyValue <= 0) {
      return [];
    }
    
    // Recommend solar panels
    final recommendedPanels = solarPanels.where((panel) {
      final panelCapacity = double.tryParse(panel.capacity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return panelCapacity >= energyValue * 0.2 && panelCapacity <= energyValue * 0.3;
    }).toList();
    
    // Recommend batteries
    final recommendedBatteries = batteries.where((battery) {
      final batteryCapacity = double.tryParse(battery.capacity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return batteryCapacity >= energyValue * 0.8 && batteryCapacity <= energyValue * 1.2;
    }).toList();
    
    // Recommend inverters
    final recommendedInverters = inverters.where((inverter) {
      final inverterCapacity = double.tryParse(inverter.capacity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return inverterCapacity >= energyValue * 0.9 && inverterCapacity <= energyValue * 1.1;
    }).toList();
    
    // Combine recommendations
    final recommendations = [...recommendedPanels, ...recommendedBatteries, ...recommendedInverters];
    
    // If no specific recommendations, return some default products
    if (recommendations.isEmpty) {
      return _products.where((product) => 
          product.category == ProductCategory.solarPanel || 
          product.category == ProductCategory.battery || 
          product.category == ProductCategory.inverter)
          .take(6)
          .toList();
    }
    
    return recommendations;
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}