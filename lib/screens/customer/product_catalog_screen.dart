import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';

/// ProductCatalogScreen displays a list of products with filtering options
/// Allows users to browse, search, filter, and select products
class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  _ProductCatalogScreenState createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  ProductCategory _selectedCategory = ProductCategory.solarPanel;
  String _searchQuery = '';
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBrand;
  double _minPrice = 0;
  double _maxPrice = 1000000;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();

    // Set max price based on the most expensive product
    if (productProvider.products.isNotEmpty) {
      final highestPrice = productProvider.products
          .map((p) => p.price)
          .reduce((a, b) => a > b ? a : b);

      setState(() {
        _maxPrice = highestPrice.ceilToDouble();
      });
    }
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _selectCategory(ProductCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _resetFilters() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _selectedBrand = null;
      _minPrice = 0;

      if (productProvider.products.isNotEmpty) {
        final highestPrice = productProvider.products
            .map((p) => p.price)
            .reduce((a, b) => a > b ? a : b);
        _maxPrice = highestPrice.ceilToDouble();
      } else {
        _maxPrice = 1000000;
      }
    });
  }

  List<ProductModel> _getFilteredProducts() {
    final productProvider = Provider.of<ProductProvider>(context);

    // Start with category filter
    List<ProductModel> filteredProducts;
    switch (_selectedCategory) {
      case ProductCategory.solarPanel:
        filteredProducts = productProvider.solarPanels;
        break;
      case ProductCategory.battery:
        filteredProducts = productProvider.batteries;
        break;
      case ProductCategory.inverter:
        filteredProducts = productProvider.inverters;
        break;
      case ProductCategory.stand:
        filteredProducts = productProvider.stands;
        break;
      case ProductCategory.accessory:
        filteredProducts = productProvider.accessories;
        break;
    }

    // Apply search filter if search query exists
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) => 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.brand.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply brand filter if selected
    if (_selectedBrand != null) {
      filteredProducts = filteredProducts.where((product) => 
          product.brand == _selectedBrand
      ).toList();
    }

    // Apply price range filter
    filteredProducts = filteredProducts.where((product) => 
        product.price >= _minPrice && product.price <= _maxPrice
    ).toList();

    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final filteredProducts = _getFilteredProducts();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar 
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _applySearch,
                autofocus: true,
              )
            : Text('Product Catalog'),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCategoryTab(ProductCategory.solarPanel, 'Solar Panels', Icons.solar_power),
                _buildCategoryTab(ProductCategory.battery, 'Batteries', Icons.battery_full),
                _buildCategoryTab(ProductCategory.inverter, 'Inverters', Icons.electrical_services),
                _buildCategoryTab(ProductCategory.stand, 'Stands', Icons.view_in_ar),
                _buildCategoryTab(ProductCategory.accessory, 'Accessories', Icons.cable),
              ],
            ),
          ),

          // Filters section
          if (_showFilters)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Brand filter
                  Text(
                    'Brand',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 8),

                  Container(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('All'),
                            selected: _selectedBrand == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedBrand = null;
                                });
                              }
                            },
                          ),
                        ),
                        ...productProvider.availableBrands.map((brand) => 
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(brand),
                              selected: _selectedBrand == brand,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBrand = selected ? brand : null;
                                });
                              },
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Price range filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price Range',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PKR ${_minPrice.toStringAsFixed(0)} - PKR ${_maxPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: productProvider.products.isEmpty 
                        ? 1000000 
                        : productProvider.products
                            .map((p) => p.price)
                            .reduce((a, b) => a > b ? a : b)
                            .ceilToDouble(),
                    divisions: 100,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.primaryColor.withOpacity(0.2),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),

                  SizedBox(height: 16),

                  // Reset filters button
                  Center(
                    child: TextButton.icon(
                      onPressed: _resetFilters,
                      icon: Icon(Icons.refresh),
                      label: Text('Reset Filters'),
                    ),
                  ),
                ],
              ),
            ),

          // Results count and sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} Products',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sort',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.sort,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (value == 'price_low_high') {
                        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                      } else if (value == 'price_high_low') {
                        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                      } else if (value == 'name_a_z') {
                        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
                      } else if (value == 'name_z_a') {
                        filteredProducts.sort((a, b) => b.name.compareTo(a.name));
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'price_low_high',
                      child: Text('Price: Low to High'),
                    ),
                    PopupMenuItem(
                      value: 'price_high_low',
                      child: Text('Price: High to Low'),
                    ),
                    PopupMenuItem(
                      value: 'name_a_z',
                      child: Text('Name: A to Z'),
                    ),
                    PopupMenuItem(
                      value: 'name_z_a',
                      child: Text('Name: Z to A'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: productProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search query',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initializeProducts,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: MasonryGridView.count(
                            crossAxisCount: size.width > 600 ? 3 : 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductCard(context, product);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(ProductCategory category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _selectCategory(category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: product.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: product.mainImageUrl,
                  fit: BoxFit.cover,
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
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Product name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4),

                  // Brand
                  Text(
                    product.brand,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Price
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      color: AppTheme.currencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Stock status
                  Row(
                    children: [
                      Icon(
                        product.isInStock ? Icons.check_circle : Icons.cancel,
                        color: product.isInStock ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        product.isInStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: product.isInStock ? Colors.green : Colors.red,
                          fontSize: 12,
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
    );
  }
}
