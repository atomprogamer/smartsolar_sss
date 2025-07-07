import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import 'cart_provider.dart';

/// Provider class for managing order data with cart integration
class CartOrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CartProvider _cartProvider;

  List<OrderModel> _userOrders = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _error;

  /// Constructor
  CartOrderProvider(this._cartProvider);

  /// Get user orders
  List<OrderModel> get userOrders => _userOrders;

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
      _error = null; // Clear any previous errors
      notifyListeners();

      // Clear existing orders to ensure we're not showing stale data
      _userOrders = [];

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: _auth.currentUser!.uid)
              .orderBy('orderDate', descending: true)
              .get();

      if (ordersSnapshot.docs.isEmpty) {
        // No orders found for this user
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        try {
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
        } catch (itemError) {
          print('Error loading items for order ${doc.id}: $itemError');
          // Continue with next order even if this one fails
        }
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
      _error = null; // Clear any previous errors
      notifyListeners();

      // Clear existing orders to ensure we're not showing stale data
      _allOrders = [];

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .get();

      if (ordersSnapshot.docs.isEmpty) {
        // No orders found
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        try {
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
        } catch (itemError) {
          print('Error loading items for order ${doc.id}: $itemError');
          // Continue with next order even if this one fails
        }
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
      _error = null; // Clear any previous errors
      notifyListeners();

      final statusString = status.toString().split('.').last;

      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('status', isEqualTo: statusString)
              .orderBy('orderDate', descending: true)
              .get();

      if (ordersSnapshot.docs.isEmpty) {
        // No orders found with this status
        _isLoading = false;
        notifyListeners();
        return [];
      }

      final List<OrderModel> orders = [];

      for (final doc in ordersSnapshot.docs) {
        try {
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
        } catch (itemError) {
          print('Error loading items for order ${doc.id}: $itemError');
          // Continue with next order even if this one fails
        }
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

      // Also check in all orders list (for admin)
      final adminLocalOrder = _allOrders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => OrderModel.empty(),
      );

      if (adminLocalOrder.id.isNotEmpty) {
        return adminLocalOrder;
      }

      _isLoading = true;
      _error = null; // Clear any previous errors
      notifyListeners();

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      try {
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
      } catch (itemError) {
        print('Error loading items for order $orderId: $itemError');
        _isLoading = false;
        _error = 'Error loading order items: $itemError';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return null;
    }
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

      if (_cartProvider.cartItems.isEmpty) {
        _error = 'Cart is empty';
        notifyListeners();
        return null;
      }

      _isLoading = true;
      notifyListeners();

      // Create order
      final orderRef = _firestore.collection('orders').doc();

      final totalAmount = _cartProvider.cartTotal;
      final cartItems = _cartProvider.cartItems;

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) => 
        OrderItemModel.fromCartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + cartItem.id,
          orderId: orderRef.id,
          cartItem: cartItem,
        )
      ).toList();

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
        items: orderItems,
      );

      await orderRef.set(newOrder.toMap());

      // Create order items
      final batch = _firestore.batch();

      for (final item in orderItems) {
        final itemRef = _firestore.collection('orderItems').doc(item.id);
        batch.set(itemRef, item.toMap());
      }

      await batch.commit();

      // Add to local list
      _userOrders.add(newOrder);

      // Clear cart
      _cartProvider.clearCart();

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
