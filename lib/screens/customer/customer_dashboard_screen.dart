import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../models/product_model.dart';
import '../../models/service_model.dart';

/// CustomerDashboardScreen is the main screen for customers after login
/// Redesigned to be more user-friendly with product categories and featured services
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({Key? key}) : super(key: key);

  @override
  _CustomerDashboardScreenState createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      await Future.wait([
        productProvider.fetchProducts(),
        productProvider.fetchFeaturedProducts(),
        serviceProvider.fetchServices(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.name ?? 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.cart);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      _buildWelcomeSection(userName),

                      SizedBox(height: 24),

                      // Quick actions
                      _buildQuickActions(),

                      SizedBox(height: 24),

                      // Product categories
                      _buildSectionTitle('Product Categories'),
                      SizedBox(height: 16),
                      _buildProductCategories(),

                      SizedBox(height: 24),

                      // Featured products
                      _buildSectionTitle('Featured Products'),
                      SizedBox(height: 16),
                      _buildFeaturedProducts(),

                      SizedBox(height: 24),

                      // Services
                      _buildSectionTitle('Our Services'),
                      SizedBox(height: 16),
                      _buildServices(),

                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 30,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore our solar products and services',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickActionItem(
            icon: Icons.shopping_bag,
            label: 'Products',
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.productCatalog),
            color: Colors.blue,
          ),
          _buildQuickActionItem(
            icon: Icons.miscellaneous_services,
            label: 'Services',
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.serviceCatalog),
            color: Colors.orange,
          ),
          _buildQuickActionItem(
            icon: Icons.calculate,
            label: 'Cost Estimator',
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.costEstimator),
            color: Colors.green,
          ),
          _buildQuickActionItem(
            icon: Icons.support_agent,
            label: 'Consultation',
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.consultation),
            color: Colors.purple,
          ),
          _buildQuickActionItem(
            icon: Icons.history,
            label: 'Orders',
            onTap: () => AppRoutes.navigateTo(context, AppRoutes.orderHistory),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            if (title.contains('Product')) {
              AppRoutes.navigateTo(context, AppRoutes.productCatalog);
            } else if (title.contains('Service')) {
              AppRoutes.navigateTo(context, AppRoutes.serviceCatalog);
            }
          },
          child: Text('See All'),
        ),
      ],
    );
  }

  Widget _buildProductCategories() {
    final categories = [
      {
        'name': 'Solar Panels',
        'icon': Icons.solar_power,
        'color': Colors.amber,
        'category': ProductCategory.solarPanel,
      },
      {
        'name': 'Batteries',
        'icon': Icons.battery_full,
        'color': Colors.green,
        'category': ProductCategory.battery,
      },
      {
        'name': 'Inverters',
        'icon': Icons.electrical_services,
        'color': Colors.blue,
        'category': ProductCategory.inverter,
      },
      {
        'name': 'Stands',
        'icon': Icons.architecture,
        'color': Colors.brown,
        'category': ProductCategory.stand,
      },
      {
        'name': 'Accessories',
        'icon': Icons.cable,
        'color': Colors.purple,
        'category': ProductCategory.accessory,
      },
    ];

    return Container(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                // Navigate to product catalog with category filter
                AppRoutes.navigateTo(context, AppRoutes.productCatalog);
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: category['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    final productProvider = Provider.of<ProductProvider>(context);
    final featuredProducts = productProvider.featuredProducts;

    if (featuredProducts.isEmpty) {
      return Center(
        child: Text('No featured products available'),
      );
    }

    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredProducts.length > 5 ? 5 : featuredProducts.length,
        itemBuilder: (context, index) {
          final product = featuredProducts[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.productDetails,
                    arguments: product.id,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product icon
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          product.categoryIconData,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            product.formattedPrice,
                            style: TextStyle(
                              color: AppTheme.currencyColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServices() {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final services = serviceProvider.services;

    if (services.isEmpty) {
      return Center(
        child: Text('No services available'),
      );
    }

    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length > 5 ? 5 : services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.serviceDetails,
                    arguments: service.id,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service icon
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          service.serviceTypeIconData,
                          size: 40,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              service.serviceType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            service.formattedPrice,
                            style: TextStyle(
                              color: AppTheme.currencyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
