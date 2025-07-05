import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/product_model.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';

/// ProductDetailsScreen displays detailed information about a selected product
/// Allows users to view images, specifications, and add the product to cart
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isLoading = false;
  ProductModel? _product;
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _showFullDescription = false;
  bool _addingToCart = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    final productId = ModalRoute.of(context)?.settings.arguments as String?;

    if (productId == null) {
      setState(() {
        _errorMessage = 'Product ID not provided';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(productId);

      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load product details: $e';
      });
    }
  }

  void _incrementQuantity() {
    if (_product == null) return;

    setState(() {
      if (_quantity < _product!.stockQuantity) {
        _quantity++;
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  void _addToCart() {
    if (_product == null) return;

    setState(() {
      _addingToCart = true;
      _errorMessage = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.addToCart(_product!, _quantity);

      setState(() {
        _addingToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product!.name} added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cart);
            },
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _addingToCart = false;
        _errorMessage = 'Failed to add to cart: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Product Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Product Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProductDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Product Details')),
        body: Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cart);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        items: _product!.imageUrls.isEmpty
                            ? [
                                Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ]
                            : _product!.imageUrls.map((url) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                      ),

                      // Image indicators
                      if (_product!.imageUrls.length > 1)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _product!.imageUrls.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? AppTheme.primaryColor
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),

                  // Product info
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and brand
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _product!.categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _product!.brand,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Product name
                        Text(
                          _product!.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 16),

                        // Price and stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _product!.formattedPrice,
                              style: TextStyle(
                                color: AppTheme.currencyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  _product!.isInStock ? Icons.check_circle : Icons.cancel,
                                  color: _product!.isInStock ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _product!.isInStock 
                                      ? 'In Stock (${_product!.stockQuantity})' 
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    color: _product!.isInStock ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Description
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          _product!.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: _showFullDescription ? null : 3,
                          overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                        ),

                        if (_product!.description.length > 150)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showFullDescription = !_showFullDescription;
                              });
                            },
                            child: Text(
                              _showFullDescription ? 'Show Less' : 'Read More',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        SizedBox(height: 24),

                        // Technical specifications
                        if (_product!.technicalSpecifications != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Technical Specifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Html(
                                data: _product!.technicalSpecifications!,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize(14),
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  "li": Style(
                                    margin: Margins.only(bottom: 8),
                                  ),
                                },
                              ),

                              SizedBox(height: 24),
                            ],
                          ),

                        // Installation type
                        if (_product!.installationType != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Installation Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                _product!.installationType!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),

                              SizedBox(height: 24),
                            ],
                          ),

                        // Capacity
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capacity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              _product!.capacity,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with add to cart
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: _quantity > 1 ? _decrementQuantity : null,
                            color: _quantity > 1 ? AppTheme.primaryColor : Colors.grey,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _quantity.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _quantity < _product!.stockQuantity 
                                ? _incrementQuantity 
                                : null,
                            color: _quantity < _product!.stockQuantity 
                                ? AppTheme.primaryColor 
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Add to cart button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _product!.isInStock && !_addingToCart 
                            ? _addToCart 
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _addingToCart
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
