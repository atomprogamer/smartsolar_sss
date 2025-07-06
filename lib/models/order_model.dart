import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

/// Enum for order status
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  completed,
}

/// Enum for payment methods
enum PaymentMethod {
  bankTransfer,
  cashOnDelivery,
}

/// Order model class based on the class diagram
class OrderModel {
  final String id;
  final String userId;
  final DateTime orderDate;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? city;
  final GeoPoint? location;
  final List<OrderItemModel> items;
  final String? paymentId;

  /// Constructor
  OrderModel({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
    this.city,
    this.location,
    required this.items,
    this.paymentId,
  });

  /// Create an empty order
  factory OrderModel.empty() {
    return OrderModel(
      id: '',
      userId: '',
      orderDate: DateTime.now(),
      totalAmount: 0.0,
      status: OrderStatus.pending,
      paymentMethod: PaymentMethod.bankTransfer,
      shippingAddress: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
    );
  }

  /// Create an order from a Firebase document snapshot
  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot, List<OrderItemModel> items) {
    final data = snapshot.data() as Map<String, dynamic>;

    return OrderModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: _getOrderStatusFromString(data['status'] ?? 'pending'),
      paymentMethod: _getPaymentMethodFromString(data['paymentMethod'] ?? 'bankTransfer'),
      shippingAddress: data['shippingAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      city: data['city'],
      location: data['location'] as GeoPoint?,
      items: items,
      paymentId: data['paymentId'],
    );
  }

  /// Convert order to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderDate': Timestamp.fromDate(orderDate),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'shippingAddress': shippingAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'city': city,
      'location': location,
      'paymentId': paymentId,
    };
  }

  /// Create a copy of the order with updated fields
  OrderModel copyWith({
    String? id,
    String? userId,
    DateTime? orderDate,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? shippingAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? city,
    GeoPoint? location,
    List<OrderItemModel>? items,
    String? paymentId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      city: city ?? this.city,
      location: location ?? this.location,
      items: items ?? this.items,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  /// Helper method to convert string to OrderStatus enum
  static OrderStatus _getOrderStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pending;
    }
  }

  /// Helper method to convert string to PaymentMethod enum
  static PaymentMethod _getPaymentMethodFromString(String method) {
    switch (method) {
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'cashOnDelivery':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.bankTransfer;
    }
  }

  /// Get formatted total amount in Pakistani Rupees (PKR)
  String get formattedTotalAmount => 'PKR ${totalAmount.toStringAsFixed(2)}';

  /// Get formatted order date
  String get formattedOrderDate {
    final day = orderDate.day.toString().padLeft(2, '0');
    final month = orderDate.month.toString().padLeft(2, '0');
    final year = orderDate.year.toString();
    return '$day-$month-$year';
  }

  /// Get status name as a string
  String get statusName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  /// Get payment method name as a string
  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  /// Check if the order is pending
  bool get isPending => status == OrderStatus.pending;

  /// Check if the order is processing
  bool get isProcessing => status == OrderStatus.processing;

  /// Check if the order is shipped
  bool get isShipped => status == OrderStatus.shipped;

  /// Check if the order is delivered
  bool get isDelivered => status == OrderStatus.delivered;

  /// Check if the order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Check if the order is completed
  bool get isCompleted => status == OrderStatus.completed;

  /// Check if the order can be cancelled
  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.processing;
}

/// Enum for order item type
enum OrderItemType {
  product,
  service,
}

/// OrderItem model class based on the class diagram
class OrderItemModel {
  final String id;
  final String orderId;
  final OrderItemType itemType;
  final String itemId; // productId or serviceId
  final int quantity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? itemName;
  final String? itemImage;

  /// Constructor
  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.itemType,
    required this.itemId,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.itemName,
    this.itemImage,
  });

  /// Create an empty order item
  factory OrderItemModel.empty() {
    return OrderItemModel(
      id: '',
      orderId: '',
      itemType: OrderItemType.product,
      itemId: '',
      quantity: 0,
      price: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create an order item from a product
  factory OrderItemModel.fromProduct({
    required String id,
    required String orderId,
    required String productId,
    required int quantity,
    required double price,
    required String? productName,
    required String? productImage,
  }) {
    return OrderItemModel(
      id: id,
      orderId: orderId,
      itemType: OrderItemType.product,
      itemId: productId,
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: productName,
      itemImage: productImage,
    );
  }

  /// Create an order item from a service
  factory OrderItemModel.fromService({
    required String id,
    required String orderId,
    required String serviceId,
    required int quantity,
    required double price,
    required String? serviceName,
    required String? serviceImage,
  }) {
    return OrderItemModel(
      id: id,
      orderId: orderId,
      itemType: OrderItemType.service,
      itemId: serviceId,
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: serviceName,
      itemImage: serviceImage,
    );
  }

  /// Create an order item from a cart item
  factory OrderItemModel.fromCartItem({
    required String id,
    required String orderId,
    required CartItemModel cartItem,
  }) {
    return OrderItemModel(
      id: id,
      orderId: orderId,
      itemType: cartItem.isProduct ? OrderItemType.product : OrderItemType.service,
      itemId: cartItem.itemId,
      quantity: cartItem.quantity,
      price: cartItem.price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: cartItem.itemName,
      itemImage: cartItem.itemImage,
    );
  }

  /// Create an order item from a Firebase document snapshot
  factory OrderItemModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return OrderItemModel(
      id: snapshot.id,
      orderId: data['orderId'] ?? '',
      itemType: _getItemTypeFromString(data['itemType'] ?? 'product'),
      itemId: data['itemId'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      itemName: data['itemName'],
      itemImage: data['itemImage'],
    );
  }

  /// Convert order item to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'itemType': itemType.toString().split('.').last,
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'itemName': itemName,
      'itemImage': itemImage,
    };
  }

  /// Create a copy of the order item with updated fields
  OrderItemModel copyWith({
    String? id,
    String? orderId,
    OrderItemType? itemType,
    String? itemId,
    int? quantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? itemImage,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      itemImage: itemImage ?? this.itemImage,
    );
  }

  /// Helper method to convert string to OrderItemType enum
  static OrderItemType _getItemTypeFromString(String type) {
    switch (type) {
      case 'product':
        return OrderItemType.product;
      case 'service':
        return OrderItemType.service;
      default:
        return OrderItemType.product;
    }
  }

  /// Get formatted price in Pakistani Rupees (PKR)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(2)}';

  /// Get total price for this item
  double get totalPrice => price * quantity;

  /// Get formatted total price in Pakistani Rupees (PKR)
  String get formattedTotalPrice => 'PKR ${totalPrice.toStringAsFixed(2)}';

  /// Check if this is a product
  bool get isProduct => itemType == OrderItemType.product;

  /// Check if this is a service
  bool get isService => itemType == OrderItemType.service;
}
