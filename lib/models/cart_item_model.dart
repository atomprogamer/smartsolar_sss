import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for item type
enum ItemType {
  product,
  service,
}

/// CartItem model class
class CartItemModel {
  final String id;
  final ItemType itemType;
  final String itemId; // productId or serviceId
  final int quantity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? itemName;
  final String? itemImage;

  /// Constructor
  CartItemModel({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.itemName,
    this.itemImage,
  });

  /// Create an empty cart item
  factory CartItemModel.empty() {
    return CartItemModel(
      id: '',
      itemType: ItemType.product,
      itemId: '',
      quantity: 0,
      price: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a cart item from a product
  factory CartItemModel.fromProduct({
    required String id,
    required String productId,
    required int quantity,
    required double price,
    required String? productName,
    required String? productImage,
  }) {
    return CartItemModel(
      id: id,
      itemType: ItemType.product,
      itemId: productId,
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: productName,
      itemImage: productImage,
    );
  }

  /// Create a cart item from a service
  factory CartItemModel.fromService({
    required String id,
    required String serviceId,
    required int quantity,
    required double price,
    required String? serviceName,
    required String? serviceImage,
  }) {
    return CartItemModel(
      id: id,
      itemType: ItemType.service,
      itemId: serviceId,
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      itemName: serviceName,
      itemImage: serviceImage,
    );
  }

  /// Create a cart item from a Firebase document snapshot
  factory CartItemModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return CartItemModel(
      id: snapshot.id,
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

  /// Convert cart item to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
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

  /// Create a copy of the cart item with updated fields
  CartItemModel copyWith({
    String? id,
    ItemType? itemType,
    String? itemId,
    int? quantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? itemImage,
  }) {
    return CartItemModel(
      id: id ?? this.id,
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

  /// Helper method to convert string to ItemType enum
  static ItemType _getItemTypeFromString(String type) {
    switch (type) {
      case 'product':
        return ItemType.product;
      case 'service':
        return ItemType.service;
      default:
        return ItemType.product;
    }
  }

  /// Get formatted price in Pakistani Rupees (PKR)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(2)}';

  /// Get total price for this item
  double get totalPrice => price * quantity;

  /// Get formatted total price in Pakistani Rupees (PKR)
  String get formattedTotalPrice => 'PKR ${totalPrice.toStringAsFixed(2)}';

  /// Check if this is a product
  bool get isProduct => itemType == ItemType.product;

  /// Check if this is a service
  bool get isService => itemType == ItemType.service;
}