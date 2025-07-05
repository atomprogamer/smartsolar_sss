import 'package:cloud_firestore/cloud_firestore.dart';

/// CostEstimate model class based on the class diagram
class CostEstimateModel {
  final String id;
  final String userId;
  final String energyRequirement;
  final String location;
  final double totalCost;
  final double equipmentCost;
  final double installationCost;
  final double maintenanceCost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeoPoint? locationCoordinates;
  final String? city;
  final List<RecommendedProductModel>? recommendedProducts;
  final String? notes;
  
  /// Constructor
  CostEstimateModel({
    required this.id,
    required this.userId,
    required this.energyRequirement,
    required this.location,
    required this.totalCost,
    required this.equipmentCost,
    required this.installationCost,
    required this.maintenanceCost,
    required this.createdAt,
    required this.updatedAt,
    this.locationCoordinates,
    this.city,
    this.recommendedProducts,
    this.notes,
  });
  
  /// Create an empty cost estimate
  factory CostEstimateModel.empty() {
    return CostEstimateModel(
      id: '',
      userId: '',
      energyRequirement: '',
      location: '',
      totalCost: 0.0,
      equipmentCost: 0.0,
      installationCost: 0.0,
      maintenanceCost: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a cost estimate from a Firebase document snapshot
  factory CostEstimateModel.fromSnapshot(DocumentSnapshot snapshot, {List<RecommendedProductModel>? products}) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return CostEstimateModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      energyRequirement: data['energyRequirement'] ?? '',
      location: data['location'] ?? '',
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      equipmentCost: (data['equipmentCost'] ?? 0.0).toDouble(),
      installationCost: (data['installationCost'] ?? 0.0).toDouble(),
      maintenanceCost: (data['maintenanceCost'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      locationCoordinates: data['locationCoordinates'] as GeoPoint?,
      city: data['city'],
      recommendedProducts: products,
      notes: data['notes'],
    );
  }
  
  /// Convert cost estimate to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'energyRequirement': energyRequirement,
      'location': location,
      'totalCost': totalCost,
      'equipmentCost': equipmentCost,
      'installationCost': installationCost,
      'maintenanceCost': maintenanceCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'locationCoordinates': locationCoordinates,
      'city': city,
      'notes': notes,
    };
  }
  
  /// Create a copy of the cost estimate with updated fields
  CostEstimateModel copyWith({
    String? id,
    String? userId,
    String? energyRequirement,
    String? location,
    double? totalCost,
    double? equipmentCost,
    double? installationCost,
    double? maintenanceCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? locationCoordinates,
    String? city,
    List<RecommendedProductModel>? recommendedProducts,
    String? notes,
  }) {
    return CostEstimateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      energyRequirement: energyRequirement ?? this.energyRequirement,
      location: location ?? this.location,
      totalCost: totalCost ?? this.totalCost,
      equipmentCost: equipmentCost ?? this.equipmentCost,
      installationCost: installationCost ?? this.installationCost,
      maintenanceCost: maintenanceCost ?? this.maintenanceCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      city: city ?? this.city,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      notes: notes ?? this.notes,
    );
  }
  
  /// Get formatted total cost in Pakistani Rupees (PKR)
  String get formattedTotalCost => 'PKR ${totalCost.toStringAsFixed(2)}';
  
  /// Get formatted equipment cost in Pakistani Rupees (PKR)
  String get formattedEquipmentCost => 'PKR ${equipmentCost.toStringAsFixed(2)}';
  
  /// Get formatted installation cost in Pakistani Rupees (PKR)
  String get formattedInstallationCost => 'PKR ${installationCost.toStringAsFixed(2)}';
  
  /// Get formatted maintenance cost in Pakistani Rupees (PKR)
  String get formattedMaintenanceCost => 'PKR ${maintenanceCost.toStringAsFixed(2)}';
  
  /// Get formatted creation date
  String get formattedCreatedAt {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    return '$day-$month-$year';
  }
}

/// RecommendedProduct model class for cost estimates
class RecommendedProductModel {
  final String productId;
  final String productName;
  final String productCategory;
  final int quantity;
  final double price;
  final String? imageUrl;
  
  /// Constructor
  RecommendedProductModel({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });
  
  /// Create a recommended product from a map
  factory RecommendedProductModel.fromMap(Map<String, dynamic> map) {
    return RecommendedProductModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productCategory: map['productCategory'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }
  
  /// Convert recommended product to a map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productCategory': productCategory,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
  
  /// Get total price for this recommended product
  double get totalPrice => price * quantity;
  
  /// Get formatted price in Pakistani Rupees (PKR)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(2)}';
  
  /// Get formatted total price in Pakistani Rupees (PKR)
  String get formattedTotalPrice => 'PKR ${totalPrice.toStringAsFixed(2)}';
}

/// Payment model class based on the class diagram
class PaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final String paymentMethod;
  final DateTime transactionDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transactionId;
  final String? receiptUrl;
  
  /// Constructor
  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.receiptUrl,
  });
  
  /// Create an empty payment
  factory PaymentModel.empty() {
    return PaymentModel(
      id: '',
      orderId: '',
      amount: 0.0,
      paymentMethod: 'bankTransfer',
      transactionDate: DateTime.now(),
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a payment from a Firebase document snapshot
  factory PaymentModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return PaymentModel(
      id: snapshot.id,
      orderId: data['orderId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'bankTransfer',
      transactionDate: (data['transactionDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      transactionId: data['transactionId'],
      receiptUrl: data['receiptUrl'],
    );
  }
  
  /// Convert payment to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
    };
  }
  
  /// Create a copy of the payment with updated fields
  PaymentModel copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? paymentMethod,
    DateTime? transactionDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? transactionId,
    String? receiptUrl,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
  
  /// Get formatted amount in Pakistani Rupees (PKR)
  String get formattedAmount => 'PKR ${amount.toStringAsFixed(2)}';
  
  /// Get formatted transaction date
  String get formattedTransactionDate {
    final day = transactionDate.day.toString().padLeft(2, '0');
    final month = transactionDate.month.toString().padLeft(2, '0');
    final year = transactionDate.year.toString();
    return '$day-$month-$year';
  }
  
  /// Check if the payment is pending
  bool get isPending => status.toLowerCase() == 'pending';
  
  /// Check if the payment is completed
  bool get isCompleted => status.toLowerCase() == 'completed';
  
  /// Check if the payment is failed
  bool get isFailed => status.toLowerCase() == 'failed';
  
  /// Get payment method display name
  String get paymentMethodDisplayName {
    switch (paymentMethod.toLowerCase()) {
      case 'banktransfer':
        return 'Bank Transfer';
      case 'cashondelivery':
        return 'Cash on Delivery';
      default:
        return paymentMethod;
    }
  }
  
  /// Get status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}