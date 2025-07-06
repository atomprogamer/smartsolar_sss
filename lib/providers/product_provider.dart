import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../data/product_data.dart';

/// Provider class for managing product data
class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = false;
  String? _error;

  /// Constructor - initialize product data
  ProductProvider() {
    initializeProductData();
  }

  /// Initialize product data
  Future<void> initializeProductData() async {
    try {
      await fetchProducts();
      await fetchFeaturedProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

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

  /// Load products from local dataset
  void loadLocalProducts() {
    try {
      _isLoading = true;
      notifyListeners();

      // Load products from the local dataset
      _products = allProducts;

      // Set featured products (first 5 products from each category)
      _featuredProducts = [
        ...solarPanels.take(2),
        ...batteries.take(1),
        ...inverters.take(1),
        ...stands.take(1),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch all products
  Future<void> fetchProducts() async {
    try {
      _isLoading = true;
      notifyListeners();

      try {
        // Try to fetch from Firestore first
        final productsSnapshot = await _firestore.collection('products').get();

        if (productsSnapshot.docs.isNotEmpty) {
          _products = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
        } else {
          // If no products in Firestore, load from local dataset
          loadLocalProducts();
        }
      } catch (firestoreError) {
        // If Firestore fetch fails, load from local dataset
        print('Firestore fetch failed: $firestoreError. Loading local data instead.');
        loadLocalProducts();
      }

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

      try {
        // Try to fetch from Firestore first
        final productsSnapshot = await _firestore.collection('products')
            .where('featured', isEqualTo: true)
            .limit(10)
            .get();

        if (productsSnapshot.docs.isNotEmpty) {
          _featuredProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
        } else {
          // If no featured products in Firestore, create from local dataset
          if (_products.isEmpty) {
            // Load all products first if they're not already loaded
            loadLocalProducts();
          } else {
            // Just set featured products from existing products
            _featuredProducts = [
              ...solarPanels.take(2),
              ...batteries.take(1),
              ...inverters.take(1),
              ...stands.take(1),
            ];
          }
        }
      } catch (firestoreError) {
        // If Firestore fetch fails, create from local dataset
        print('Firestore featured products fetch failed: $firestoreError. Using local data instead.');
        if (_products.isEmpty) {
          // Load all products first if they're not already loaded
          loadLocalProducts();
        } else {
          // Just set featured products from existing products
          _featuredProducts = [
            ...solarPanels.take(2),
            ...batteries.take(1),
            ...inverters.take(1),
            ...stands.take(1),
          ];
        }
      }

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

      List<ProductModel> categoryProducts = [];

      try {
        // Try to fetch from Firestore first
        final categoryString = category.toString().split('.').last;

        final productsSnapshot = await _firestore.collection('products')
            .where('category', isEqualTo: categoryString)
            .get();

        if (productsSnapshot.docs.isNotEmpty) {
          categoryProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
        } else {
          // If no products in this category in Firestore, get from local dataset
          if (_products.isEmpty) {
            // Load all products first if they're not already loaded
            loadLocalProducts();
          }

          // Filter products by category
          switch (category) {
            case ProductCategory.solarPanel:
              categoryProducts = solarPanels;
              break;
            case ProductCategory.battery:
              categoryProducts = batteries;
              break;
            case ProductCategory.inverter:
              categoryProducts = inverters;
              break;
            case ProductCategory.stand:
              categoryProducts = stands;
              break;
            case ProductCategory.accessory:
              categoryProducts = accessories;
              break;
          }
        }
      } catch (firestoreError) {
        // If Firestore fetch fails, get from local dataset
        print('Firestore category fetch failed: $firestoreError. Using local data instead.');
        if (_products.isEmpty) {
          // Load all products first if they're not already loaded
          loadLocalProducts();
        }

        // Filter products by category
        switch (category) {
          case ProductCategory.solarPanel:
            categoryProducts = solarPanels;
            break;
          case ProductCategory.battery:
            categoryProducts = batteries;
            break;
          case ProductCategory.inverter:
            categoryProducts = inverters;
            break;
          case ProductCategory.stand:
            categoryProducts = stands;
            break;
          case ProductCategory.accessory:
            categoryProducts = accessories;
            break;
        }
      }

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

      try {
        // Try to fetch from Firestore
        final productDoc = await _firestore.collection('products').doc(productId).get();

        if (productDoc.exists) {
          final product = ProductModel.fromSnapshot(productDoc);
          _isLoading = false;
          notifyListeners();
          return product;
        }
      } catch (firestoreError) {
        print('Firestore product fetch failed: $firestoreError. Searching in local data.');
      }

      // If Firestore fetch fails or product doesn't exist, search in local data
      if (_products.isEmpty) {
        // Load all products first if they're not already loaded
        loadLocalProducts();
      }

      // Search in all categories
      for (final product in allProducts) {
        if (product.id == productId) {
          _isLoading = false;
          notifyListeners();
          return product;
        }
      }

      _isLoading = false;
      notifyListeners();
      return null;
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
      List<ProductModel> results = [];

      // First try to fetch from local list
      if (_products.isNotEmpty) {
        results = _products.where((product) => 
            product.name.toLowerCase().contains(queryLower) || 
            product.description.toLowerCase().contains(queryLower)).toList();

        if (results.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return results;
        }
      }

      try {
        // If local list is empty or no results found, try Firestore
        final productsSnapshot = await _firestore.collection('products').get();

        if (productsSnapshot.docs.isNotEmpty) {
          final firestoreProducts = productsSnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

          results = firestoreProducts.where((product) => 
              product.name.toLowerCase().contains(queryLower) || 
              product.description.toLowerCase().contains(queryLower)).toList();

          if (results.isNotEmpty) {
            _isLoading = false;
            notifyListeners();
            return results;
          }
        }
      } catch (firestoreError) {
        print('Firestore search failed: $firestoreError. Using local data instead.');
      }

      // If Firestore fetch fails or no results found, load from local dataset and search
      if (_products.isEmpty) {
        loadLocalProducts();
      }

      results = allProducts.where((product) => 
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
  /// This method adds a new product to Firestore and the local list
  /// It checks if a product with the same name already exists to avoid duplication
  Future<bool> addProduct(ProductModel product) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if a product with the same name already exists
      final existingProductsQuery = await _firestore.collection('products')
          .where('name', isEqualTo: product.name)
          .get();

      if (existingProductsQuery.docs.isNotEmpty) {
        _error = 'A product with this name already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a new document with a generated ID
      final docRef = _firestore.collection('products').doc();
      final newProduct = product.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to Firestore with error handling
      try {
        await docRef.set(newProduct.toMap());
      } catch (firestoreError) {
        _error = 'Failed to save product to database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add to local list
      _products.add(newProduct);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error adding product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update product (admin only)
  /// This method updates an existing product in Firestore and the local list
  /// It ensures the product exists before updating and handles various exceptions
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the product exists
      final docRef = _firestore.collection('products').doc(product.id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = 'Product not found. It may have been deleted.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if another product with the same name exists (but different ID)
      final existingProductsQuery = await _firestore.collection('products')
          .where('name', isEqualTo: product.name)
          .get();

      for (var doc in existingProductsQuery.docs) {
        if (doc.id != product.id) {
          _error = 'Another product with this name already exists';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Update the product with the latest timestamp
      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in Firestore with error handling
      try {
        await docRef.update(updatedProduct.toMap());
      } catch (firestoreError) {
        _error = 'Failed to update product in database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update local list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      } else {
        // If not in local list, add it
        _products.add(updatedProduct);
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete product (admin only)
  /// This method deletes a product from Firestore and the local list
  /// It ensures the product exists before deleting and handles various exceptions
  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if the product exists
      final docRef = _firestore.collection('products').doc(productId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = 'Product not found. It may have been already deleted.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if the product is referenced in any orders
      try {
        final orderItemsQuery = await _firestore.collection('orderItems')
            .where('productId', isEqualTo: productId)
            .limit(1)
            .get();

        if (orderItemsQuery.docs.isNotEmpty) {
          _error = 'Cannot delete product because it is referenced in orders. Consider updating the stock to 0 instead.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (orderCheckError) {
        // If we can't check orders, proceed with deletion but log the error
        print('Error checking orders for product: $orderCheckError');
      }

      // Delete from Firestore with error handling
      try {
        await docRef.delete();
      } catch (firestoreError) {
        _error = 'Failed to delete product from database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove from local list
      _products.removeWhere((product) => product.id == productId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error deleting product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update product stock (admin only)
  /// This method updates the stock quantity of a product in Firestore and the local list
  /// It ensures the product exists before updating and handles various exceptions
  Future<bool> updateProductStock(String productId, int newStockQuantity) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate stock quantity
      if (newStockQuantity < 0) {
        _error = 'Stock quantity cannot be negative';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if the product exists
      final docRef = _firestore.collection('products').doc(productId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = 'Product not found. It may have been deleted.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update in Firestore with error handling
      try {
        await docRef.update({
          'stockQuantity': newStockQuantity,
          'updatedAt': Timestamp.now(),
        });
      } catch (firestoreError) {
        _error = 'Failed to update product stock in database: ${firestoreError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update local list
      final index = _products.indexWhere((product) => product.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stockQuantity: newStockQuantity,
          updatedAt: DateTime.now(),
        );
      } else {
        // If not in local list, fetch the product and add it
        try {
          final productData = docSnapshot.data() as Map<String, dynamic>;
          final product = ProductModel.fromSnapshot(docSnapshot);
          _products.add(product.copyWith(
            stockQuantity: newStockQuantity,
            updatedAt: DateTime.now(),
          ));
        } catch (e) {
          // Log error but don't fail the operation
          print('Error adding product to local list: $e');
        }
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating product stock: ${e.toString()}';
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

  /// Seed Firestore with product data (admin only)
  /// This method seeds Firestore with product data from the local dataset
  /// It ensures proper synchronization and handles various exceptions
  Future<bool> seedFirestoreWithProductData() async {
    try {
      _isLoading = true;
      notifyListeners();

      try {
        // Call the seedProductData method from product_data.dart
        // This method has been updated to check for duplicates and ensure real-time synchronization
        await seedProductData();
      } catch (seedError) {
        _error = 'Error seeding product data: ${seedError.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      try {
        // Reload products from Firestore to ensure local list is in sync
        await fetchProducts();
      } catch (fetchError) {
        // Log error but don't fail the operation since seeding was successful
        print('Error reloading products after seeding: $fetchError');
        // Try to load local products as a fallback
        loadLocalProducts();
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error in seedFirestoreWithProductData: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
