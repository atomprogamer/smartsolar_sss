import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for product categories
enum ProductCategory {
  solarPanel,
  battery,
  inverter,
  stand,
  accessory,
}

/// Product model class based on the class diagram
class ProductModel {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final String brand;
  final String capacity;
  final double price;
  final String? installationType;
  final String? technicalSpecifications;
  final List<String> imageUrls;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Constructor
  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.brand,
    required this.capacity,
    required this.price,
    this.installationType,
    this.technicalSpecifications,
    required this.imageUrls,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an empty product
  factory ProductModel.empty() {
    return ProductModel(
      id: '',
      name: '',
      description: '',
      category: ProductCategory.solarPanel,
      brand: '',
      capacity: '',
      price: 0.0,
      imageUrls: [],
      stockQuantity: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a product from a Firebase document snapshot
  factory ProductModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ProductModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: _getCategoryFromString(data['category'] ?? 'solarPanel'),
      brand: data['brand'] ?? '',
      capacity: data['capacity'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      installationType: data['installationType'],
      technicalSpecifications: data['technicalSpecifications'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert product to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'brand': brand,
      'capacity': capacity,
      'price': price,
      'installationType': installationType,
      'technicalSpecifications': technicalSpecifications,
      'imageUrls': imageUrls,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of the product with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    ProductCategory? category,
    String? brand,
    String? capacity,
    double? price,
    String? installationType,
    String? technicalSpecifications,
    List<String>? imageUrls,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      installationType: installationType ?? this.installationType,
      technicalSpecifications: technicalSpecifications ?? this.technicalSpecifications,
      imageUrls: imageUrls ?? this.imageUrls,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to convert string to ProductCategory enum
  static ProductCategory _getCategoryFromString(String category) {
    switch (category) {
      case 'solarPanel':
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
        return ProductCategory.solarPanel;
    }
  }

  /// Get formatted price in Pakistani Rupees (PKR)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(2)}';

  /// Check if the product is in stock
  bool get isInStock => stockQuantity > 0;

  /// Get category name as a string
  String get categoryName {
    switch (category) {
      case ProductCategory.solarPanel:
        return 'Solar Panel';
      case ProductCategory.battery:
        return 'Battery';
      case ProductCategory.inverter:
        return 'Inverter';
      case ProductCategory.stand:
        return 'Stand';
      case ProductCategory.accessory:
        return 'Accessory';
    }
  }

  /// Get the main image URL or a placeholder if no images are available
  String get mainImageUrl {
    if (imageUrls.isNotEmpty) {
      return imageUrls[0];
    }
    return 'assets/images/placeholder_product.png'; // Local asset placeholder
  }
}
