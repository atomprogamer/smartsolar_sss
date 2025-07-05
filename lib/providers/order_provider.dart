import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';

/// Provider class for managing order data
class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderModel> _userOrders = [];
  List<OrderModel> _allOrders = [];
  final List<OrderItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _error;

  /// Get user orders
  List<OrderModel> get userOrders => _userOrders;

  /// Get cart items
  List<OrderItemModel> get cartItems => _cartItems;

  /// Get pending orders
  List<OrderModel> get pendingOrders =>
      _userOrders.where((order) => order.isPending).toList();

  /// Get processing orders
  List<OrderModel> get processingOrders =>
      _userOrders.where((order) => order.isProcessing).toList();

  /// Get shipped orders
  List<OrderModel> get shippedOrders =>
      _userOrders.where((order) => order.isShipped).toList();

  /// Get delivered orders
  List<OrderModel> get deliveredOrders =>
      _userOrders.where((order) => order.isDelivered).toList();

  /// Get completed orders
  List<OrderModel> get completedOrders =>
      _userOrders.where((order) => order.isCompleted).toList();

  /// Get cancelled orders
  List<OrderModel> get cancelledOrders =>
      _userOrders.where((order) => order.isCancelled).toList();

  /// Get all orders (admin only)
  List<OrderModel> get allOrders => _allOrders;

  /// Get recent orders (admin only)
  List<OrderModel> get recentOrders => _allOrders.take(10).toList();

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

  /// Fetch user orders
  Future<void> fetchUserOrders() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }

      _isLoading = true;
      notifyListeners();

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: _auth.currentUser!.uid)
              .orderBy('orderDate', descending: true)
              .get();

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        final orderItemsSnapshot =
            await _firestore
                .collection('orderItems')
                .where('orderId', isEqualTo: doc.id)
                .get();

        final orderItems =
            orderItemsSnapshot.docs
                .map((itemDoc) => OrderItemModel.fromSnapshot(itemDoc))
                .toList();

        orders.add(OrderModel.fromSnapshot(doc, orderItems));
      }

      _userOrders = orders;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch all orders (admin only)
  Future<void> fetchAllOrders() async {
    try {
      _isLoading = true;
      notifyListeners();

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .get();

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        final orderItemsSnapshot =
            await _firestore
                .collection('orderItems')
                .where('orderId', isEqualTo: doc.id)
                .get();

        final orderItems =
            orderItemsSnapshot.docs
                .map((itemDoc) => OrderItemModel.fromSnapshot(itemDoc))
                .toList();

        orders.add(OrderModel.fromSnapshot(doc, orderItems));
      }

      _allOrders = orders;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch orders by status (admin only)
  Future<List<OrderModel>> fetchOrdersByStatus(OrderStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      final statusString = status.toString().split('.').last;

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('status', isEqualTo: statusString)
              .orderBy('orderDate', descending: true)
              .get();

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        final orderItemsSnapshot =
            await _firestore
                .collection('orderItems')
                .where('orderId', isEqualTo: doc.id)
                .get();

        final orderItems =
            orderItemsSnapshot.docs
                .map((itemDoc) => OrderItemModel.fromSnapshot(itemDoc))
                .toList();

        orders.add(OrderModel.fromSnapshot(doc, orderItems));
      }

      _isLoading = false;
      notifyListeners();

      return orders;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      // First check if the order is already in the local list
      final localOrder = _userOrders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => OrderModel.empty(),
      );

      if (localOrder.id.isNotEmpty) {
        return localOrder;
      }

      _isLoading = true;
      notifyListeners();

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final orderItemsSnapshot =
          await _firestore
              .collection('orderItems')
              .where('orderId', isEqualTo: orderId)
              .get();

      final orderItems =
          orderItemsSnapshot.docs
              .map((itemDoc) => OrderItemModel.fromSnapshot(itemDoc))
              .toList();

      final order = OrderModel.fromSnapshot(orderDoc, orderItems);

      _isLoading = false;
      notifyListeners();

      return order;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Add product to cart
  void addToCart(ProductModel product, int quantity) {
    try {
      // Check if product is already in cart
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingItemIndex != -1) {
        // Update quantity if product is already in cart
        final existingItem = _cartItems[existingItemIndex];
        _cartItems[existingItemIndex] = OrderItemModel(
          id: existingItem.id,
          orderId: existingItem.orderId,
          productId: existingItem.productId,
          quantity: existingItem.quantity + quantity,
          price: existingItem.price,
          createdAt: existingItem.createdAt,
          updatedAt: DateTime.now(),
          productName: existingItem.productName,
          productImage: existingItem.productImage,
        );
      } else {
        // Add new item to cart
        _cartItems.add(
          OrderItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            orderId: '',
            productId: product.id,
            quantity: quantity,
            price: product.price,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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

  /// Create order from cart
  Future<String?> createOrder({
    required String shippingAddress,
    required PaymentMethod paymentMethod,
    String? city,
    GeoPoint? location,
  }) async {
    try {
      if (_auth.currentUser == null) {
        _error = 'User not logged in';
        notifyListeners();
        return null;
      }

      if (_cartItems.isEmpty) {
        _error = 'Cart is empty';
        notifyListeners();
        return null;
      }

      _isLoading = true;
      notifyListeners();

      // Create order
      final orderRef = _firestore.collection('orders').doc();

      final totalAmount = cartTotal;

      final newOrder = OrderModel(
        id: orderRef.id,
        userId: _auth.currentUser!.uid,
        orderDate: DateTime.now(),
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        shippingAddress: shippingAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        city: city,
        location: location,
        items: _cartItems,
      );

      await orderRef.set(newOrder.toMap());

      // Create order items
      final batch = _firestore.batch();

      for (final item in _cartItems) {
        final itemRef = _firestore.collection('orderItems').doc();

        final orderItem = item.copyWith(id: itemRef.id, orderId: orderRef.id);

        batch.set(itemRef, orderItem.toMap());
      }

      await batch.commit();

      // Add to local list
      _userOrders.add(newOrder);

      // Clear cart
      clearCart();

      _isLoading = false;
      notifyListeners();

      return orderRef.id;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _userOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _userOrders[index] = _userOrders[index].copyWith(
          status: OrderStatus.cancelled,
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

  /// Update order status (admin only)
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      // Update local list if it's a user order
      final index = _userOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _userOrders[index] = _userOrders[index].copyWith(
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

  /// Create payment for order
  Future<bool> createPayment(
    String orderId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final paymentRef = _firestore.collection('payments').doc();

      await paymentRef.set({
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionDate': Timestamp.now(),
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update order with payment ID
      await _firestore.collection('orders').doc(orderId).update({
        'paymentId': paymentRef.id,
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

  /// Update payment status (admin only)
  Future<bool> updatePaymentStatus(String paymentId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('payments').doc(paymentId).update({
        'status': status,
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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
