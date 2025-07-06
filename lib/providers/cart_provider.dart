import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';

/// Provider class for managing cart data
class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _error;

  /// Get cart items
  List<CartItemModel> get cartItems => _cartItems;

  /// Get product items in cart
  List<CartItemModel> get productItems => 
      _cartItems.where((item) => item.isProduct).toList();

  /// Get service items in cart
  List<CartItemModel> get serviceItems => 
      _cartItems.where((item) => item.isService).toList();

  /// Get cart total
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  /// Get formatted cart total
  String get formattedCartTotal => 'PKR ${cartTotal.toStringAsFixed(2)}';

  /// Get cart item count
  int get cartItemCount => _cartItems.length;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get error => _error;

  /// Add product to cart
  void addProductToCart(ProductModel product, int quantity) {
    try {
      // Check if product is already in cart
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.isProduct && item.itemId == product.id,
      );

      if (existingItemIndex != -1) {
        // Update quantity if product is already in cart
        final existingItem = _cartItems[existingItemIndex];
        _cartItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new item to cart
        _cartItems.add(
          CartItemModel.fromProduct(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: product.id,
            quantity: quantity,
            price: product.price,
            productName: product.name,
            productImage: product.mainImageUrl,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add service to cart
  void addServiceToCart(ServiceModel service, int quantity) {
    try {
      // Check if service is already in cart
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.isService && item.itemId == service.id,
      );

      if (existingItemIndex != -1) {
        // Update quantity if service is already in cart
        final existingItem = _cartItems[existingItemIndex];
        _cartItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new item to cart
        _cartItems.add(
          CartItemModel.fromService(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            serviceId: service.id,
            quantity: quantity,
            price: service.price,
            serviceName: service.serviceType,
            serviceImage: service.mainImageUrl,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update cart item quantity
  void updateCartItemQuantity(String itemId, int quantity) {
    try {
      if (quantity <= 0) {
        removeFromCart(itemId);
        return;
      }

      final index = _cartItems.indexWhere((item) => item.id == itemId);

      if (index != -1) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: quantity,
          updatedAt: DateTime.now(),
        );

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeFromCart(String itemId) {
    try {
      _cartItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Save cart to Firestore
  Future<bool> saveCart() async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      // Delete existing cart items
      final existingCartSnapshot = await _firestore
          .collection('carts')
          .doc(_auth.currentUser!.uid)
          .collection('items')
          .get();

      final batch = _firestore.batch();

      for (final doc in existingCartSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new cart items
      for (final item in _cartItems) {
        final itemRef = _firestore
            .collection('carts')
            .doc(_auth.currentUser!.uid)
            .collection('items')
            .doc();

        batch.set(itemRef, item.toMap());
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

  /// Load cart from Firestore
  Future<bool> loadCart() async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      final cartSnapshot = await _firestore
          .collection('carts')
          .doc(_auth.currentUser!.uid)
          .collection('items')
          .get();

      _cartItems.clear();

      for (final doc in cartSnapshot.docs) {
        _cartItems.add(CartItemModel.fromSnapshot(doc));
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