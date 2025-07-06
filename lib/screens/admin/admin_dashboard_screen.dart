import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/order_provider_new.dart';
import '../../providers/knowledge_provider.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_snackbar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// AdminDashboardScreen is the main screen for admin users after login
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _drawerItems = [
    'Dashboard',
    'User Management',
    'Product Management',
    'Service Management',
    'Order Management',
    'Knowledge Base',
    'Settings',
  ];

  // Form controllers for product management
  final _productFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _technicalSpecificationsController = TextEditingController();

  // Selected product category and installation type
  dynamic _selectedCategory = 'solarPanel';
  String? _selectedInstallationType;

  // Selected images for product
  List<File> _selectedProductImages = [];
  List<String> _existingProductImageUrls = [];

  // Loading state
  bool _isProductLoading = false;
  bool _isEditingProduct = false;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Dispose product form controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _technicalSpecificationsController.dispose();
    super.dispose();
  }

  /// Reset product form fields
  void _resetProductForm() {
    _productFormKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _brandController.clear();
    _capacityController.clear();
    _priceController.clear();
    _stockQuantityController.clear();
    _technicalSpecificationsController.clear();

    setState(() {
      _selectedCategory = 'solarPanel';
      _selectedInstallationType = null;
      _selectedProductImages = [];
      _existingProductImageUrls = [];
      _isEditingProduct = false;
      _selectedProductId = null;
    });
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final cartOrderProvider = Provider.of<CartOrderProvider>(context, listen: false);

    await Future.wait<void>([
      userProvider.fetchAllUsers(),      // Fetch all users instead of just pending
      userProvider.fetchUserCounts(),    // Fetch accurate user counts
      productProvider.fetchProducts(),
      serviceProvider.fetchServices(),
      cartOrderProvider.fetchAllOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_drawerItems[_selectedIndex]),
        backgroundColor: AppTheme.secondaryColor,
      ),
      drawer: _buildDrawer(user),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer(UserModel? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Admin User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: 24.0,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(color: AppTheme.secondaryColor),
          ),
          ..._drawerItems.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            return ListTile(
              leading: Icon(_getIconForDrawerItem(index)),
              title: Text(title),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                Navigator.pop(context);
              },
            );
          }),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                AppRoutes.navigateAndRemoveUntil(context, AppRoutes.welcome);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForDrawerItem(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.inventory;
      case 3:
        return Icons.miscellaneous_services;
      case 4:
        return Icons.shopping_cart;
      case 5:
        return Icons.book;
      case 6:
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUserManagementTab();
      case 2:
        return _buildProductManagementTab();
      case 3:
        return _buildServiceManagementTab();
      case 4:
        return _buildOrderManagementTab();
      case 5:
        return _buildKnowledgeBaseTab();
      case 6:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final userProvider = Provider.of<UserProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final cartOrderProvider = Provider.of<CartOrderProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              _buildStatsGrid(
                userProvider,
                productProvider,
                serviceProvider,
                cartOrderProvider,
              ),

              SizedBox(height: 24),

              // Pending approvals
              Text(
                'Pending Approvals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPendingApprovalsList(userProvider.pendingUsers),

              SizedBox(height: 24),

              // Recent orders
              Text(
                'Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildRecentOrdersList(cartOrderProvider.recentOrders),

              SizedBox(height: 24),

              // Low stock products
              Text(
                'Low Stock Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildLowStockProductsList(
                productProvider.products
                    .where((p) => p.stockQuantity < 10)
                    .toList(),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    UserProvider userProvider,
    ProductProvider productProvider,
    ServiceProvider serviceProvider,
    CartOrderProvider cartOrderProvider,
  ) {
    final stats = [
      {
        'title': 'Total Users',
        'value': userProvider.totalUserCount.toString(),
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Total Products',
        'value': productProvider.products.length.toString(),
        'icon': Icons.inventory,
        'color': Colors.green,
      },
      {
        'title': 'Total Orders',
        'value': cartOrderProvider.allOrders.length.toString(),
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
      },
      {
        'title': 'Pending Approvals',
        'value': userProvider.pendingUserCount.toString(),
        'icon': Icons.pending_actions,
        'color': Colors.red,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 32,
                ),
              ),
              SizedBox(height: 8),
              Text(
                stat['title'] as String,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingApprovalsList(List<UserModel> pendingUsers) {
    if (pendingUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No pending approvals'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: pendingUsers.length > 5 ? 5 : pendingUsers.length,
      itemBuilder: (context, index) {
        final user = pendingUsers[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    // Approve user
                    _approveUser(user);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Reject user
                    _rejectUser(user);
                  },
                ),
              ],
            ),
            onTap: () {
              // View user details
              _showUserDetailsDialog(user);
            },
          ),
        );
      },
    );
  }

  void _approveUser(UserModel user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Approve User'),
            content: Text('Are you sure you want to approve ${user.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.approveUser(user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User approved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _rejectUser(UserModel user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reject User'),
            content: Text('Are you sure you want to reject ${user.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.rejectUser(user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Reject'),
              ),
            ],
          ),
    );
  }

  void _showUserDetailsDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('User Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserDetailItem('Name', user.name),
                  _buildUserDetailItem('Email', user.email),
                  _buildUserDetailItem('Phone', user.phoneNumber),
                  if (user.address != null)
                    _buildUserDetailItem('Address', user.address!),
                  if (user.city != null)
                    _buildUserDetailItem('City', user.city!),
                  _buildUserDetailItem(
                    'User Type',
                    user.userType.toString().split('.').last,
                  ),
                  _buildUserDetailItem(
                    'Status',
                    user.approvalStatus.toString().split('.').last,
                  ),
                  _buildUserDetailItem(
                    'Created At',
                    _formatDate(user.createdAt),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildUserDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No recent orders'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: orders.length > 5 ? 5 : orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
            ),
            title: Text('Order #${order.id.substring(0, 8)}'),
            subtitle: Text('${_formatDate(order.orderDate)} • ${order.status}'),
            trailing: Text(
              'PKR ${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              // View order details
            },
          ),
        );
      },
    );
  }

  Widget _buildLowStockProductsList(List<dynamic> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No low stock products'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: products.length > 5 ? 5 : products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(product.mainImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(product.name),
            subtitle: Text('${product.categoryName} • ${product.brand}'),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Stock: ${product.stockQuantity}',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              // View product details
            },
          ),
        );
      },
    );
  }

  Widget _buildUserManagementTab() {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Customers'),
              Tab(text: 'Staff'),
              Tab(text: 'Pending'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(userProvider.users),
                _buildUsersList(
                  userProvider.users.where((u) => u.isCustomer).toList(),
                ),
                _buildUsersList(
                  userProvider.users.where((u) => u.isStaff).toList(),
                ),
                _buildUsersList(userProvider.pendingUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(child: Text('No users found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUserTypeColor(
                user.userType,
              ).withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(color: _getUserTypeColor(user.userType)),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(
              '${user.email} • ${_getUserTypeString(user.userType)}',
            ),
            trailing:
                user.approvalStatus == ApprovalStatus.pending
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveUser(user),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectUser(user),
                        ),
                      ],
                    )
                    : _getStatusBadge(user.approvalStatus),
            onTap: () => _showUserDetailsDialog(user),
          ),
        );
      },
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.purple;
      case UserType.expert:
        return Colors.blue;
      case UserType.technician:
        return Colors.orange;
      case UserType.customer:
        return Colors.green;
      case UserType.vendor:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.expert:
        return 'Expert';
      case UserType.technician:
        return 'Technician';
      case UserType.customer:
        return 'Customer';
      case UserType.vendor:
        return 'Vendor';
      default:
        return 'Unknown';
    }
  }

  Widget _getStatusBadge(ApprovalStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApprovalStatus.approved:
        color = Colors.green;
        text = 'APPROVED';
        break;
      case ApprovalStatus.pending:
        color = Colors.orange;
        text = 'PENDING';
        break;
      case ApprovalStatus.rejected:
        color = Colors.red;
        text = 'REJECTED';
        break;
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductManagementTab() {
    final productProvider = Provider.of<ProductProvider>(context);

    if (productProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: [
              Tab(text: 'All Products'),
              Tab(text: 'Solar Panels'),
              Tab(text: 'Batteries'),
              Tab(text: 'Inverters'),
              Tab(text: 'Accessories'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show add product dialog
                    _showAddProductDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductsList(productProvider.products),
                _buildProductsList(productProvider.solarPanels),
                _buildProductsList(productProvider.batteries),
                _buildProductsList(productProvider.inverters),
                _buildProductsList(productProvider.accessories),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<dynamic> products) {
    if (products.isEmpty) {
      return Center(child: Text('No products found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(product.mainImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(product.name),
            subtitle: Text('${product.categoryName} • ${product.brand}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Show edit product dialog
                    _showEditProductDialog(product);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Show delete confirmation dialog
                    _showDeleteProductDialog(product);
                  },
                ),
              ],
            ),
            onTap: () {
              // Show product details
              _showProductDetailsDialog(product);
            },
          ),
        );
      },
    );
  }

  void _showAddProductInfoDialog() {
    // Show dialog to inform user to go to Product Management tab
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Product'),
        content: Text(
          'To add a new product, please go to the "Product Management" tab and use the "Add Product" button there.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to Product Management tab
              setState(() {
                _selectedIndex = 2; // Index of Product Management tab
              });
            },
            child: Text('Go to Product Management'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add a new product
  void _showAddProductDialog() {
    _resetProductForm();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Add New Product'),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: SingleChildScrollView(
            child: Form(
              key: _productFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.inventory),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Product Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.category),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: [
                      DropdownMenuItem(value: 'solarPanel', child: Text('Solar Panel')),
                      DropdownMenuItem(value: 'battery', child: Text('Battery')),
                      DropdownMenuItem(value: 'inverter', child: Text('Inverter')),
                      DropdownMenuItem(value: 'stand', child: Text('Stand')),
                      DropdownMenuItem(value: 'accessory', child: Text('Accessory')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Brand
                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.business),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a brand';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Capacity
                  TextFormField(
                    controller: _capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.power),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'e.g., 500W, 1000Wh, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (PKR)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'PKR ',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Please enter a valid number';
                      }
                      if (price <= 0) {
                        return 'Price must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Stock Quantity
                  TextFormField(
                    controller: _stockQuantityController,
                    decoration: InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.inventory_2),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null) {
                        return 'Please enter a valid number';
                      }
                      if (quantity < 0) {
                        return 'Quantity cannot be negative';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Installation Type (optional)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Installation Type (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.build),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'e.g., Roof-mounted, Ground-mounted, etc.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstallationType = value.isEmpty ? null : value;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Technical Specifications
                  TextFormField(
                    controller: _technicalSpecificationsController,
                    decoration: InputDecoration(
                      labelText: 'Technical Specifications',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.settings),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),

                  // Product Images
                  Text(
                    'Product Images',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _pickProductImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Add Images'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Display selected images
                  if (_selectedProductImages.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedProductImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedProductImages[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_productFormKey.currentState!.validate()) {
                _saveProduct();
                Navigator.pop(context);
              }
            },
            child: Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _showEditProductInfoDialog(dynamic product) {
    // Show dialog to inform user to go to Product Management tab
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Product'),
        content: Text(
          'To edit this product, please go to the "Product Management" tab and use the edit button next to the product.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to Product Management tab
              setState(() {
                _selectedIndex = 2; // Index of Product Management tab
              });
            },
            child: Text('Go to Product Management'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Pick product images from gallery
  Future<void> _pickProductImages() async {
    try {
      // Check if we've already reached the maximum number of images (5)
      final int currentImageCount = _existingProductImageUrls.length + _selectedProductImages.length;
      final int remainingSlots = 5 - currentImageCount;

      if (remainingSlots <= 0) {
        showCustomSnackBar(
          context: context,
          message: 'Maximum of 5 images allowed',
          isError: true,
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty) {
        return;
      }

      // Check file sizes and types
      List<XFile> validFiles = [];
      for (var file in pickedFiles) {
        // Stop adding if we've reached the limit
        if (validFiles.length >= remainingSlots) {
          showCustomSnackBar(
            context: context,
            message: 'Only $remainingSlots more image${remainingSlots > 1 ? "s" : ""} can be added',
            isError: true,
          );
          break;
        }

        final fileSize = await file.length();
        final fileExt = file.name.split('.').last.toLowerCase();

        // Check file size (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          showCustomSnackBar(
            context: context,
            message: 'File ${file.name} exceeds 5MB limit',
            isError: true,
          );
          continue;
        }

        // Check file type
        if (!['jpg', 'jpeg', 'png'].contains(fileExt)) {
          showCustomSnackBar(
            context: context,
            message: 'File ${file.name} is not a supported image type (jpg, jpeg, png)',
            isError: true,
          );
          continue;
        }

        validFiles.add(file);
      }

      if (validFiles.isNotEmpty) {
        setState(() {
          _selectedProductImages.addAll(validFiles.map((e) => File(e.path)).toList());
        });

        showCustomSnackBar(
          context: context,
          message: 'Added ${validFiles.length} image${validFiles.length > 1 ? 's' : ''}',
          isError: false,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Error picking images: $e',
        isError: true,
      );
    }
  }

  /// Upload product images to Firebase Storage and return URLs
  Future<List<String>> _uploadProductImages() async {
    // If no new images, return existing URLs
    if (_selectedProductImages.isEmpty) {
      return _existingProductImageUrls;
    }

    final List<String> imageUrls = List.from(_existingProductImageUrls);
    final storage = FirebaseStorage.instance;

    try {
      // Show progress indicator for multiple images
      if (_selectedProductImages.length > 1) {
        showCustomSnackBar(
          context: context,
          message: 'Uploading ${_selectedProductImages.length} images...',
          isError: false,
          duration: Duration(seconds: 1),
        );
      }

      for (int i = 0; i < _selectedProductImages.length; i++) {
        final image = _selectedProductImages[i];

        // Create unique filename with timestamp and index
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_$i';
        final ref = storage.ref().child('products/$fileName');

        // Upload file
        final uploadTask = ref.putFile(image);

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          if (progress % 25 == 0) { // Log at 0%, 25%, 50%, 75%, 100%
            debugPrint('Upload progress for image $i: ${progress.toStringAsFixed(0)}%');
          }
        });

        final snapshot = await uploadTask;

        // Get download URL and add to list
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Error uploading images: $e',
        isError: true,
      );

      // Return what we have so far
      return imageUrls;
    }
  }

  /// Save product to Firestore
  Future<void> _saveProduct() async {
    setState(() {
      _isProductLoading = true;
    });

    try {
      // Image upload is optional, no validation needed

      // Upload images and get URLs
      final imageUrls = await _uploadProductImages();

      // Convert string category to enum
      ProductCategory category;
      switch (_selectedCategory) {
        case 'solarPanel':
          category = ProductCategory.solarPanel;
          break;
        case 'battery':
          category = ProductCategory.battery;
          break;
        case 'inverter':
          category = ProductCategory.inverter;
          break;
        case 'stand':
          category = ProductCategory.stand;
          break;
        case 'accessory':
          category = ProductCategory.accessory;
          break;
        default:
          category = ProductCategory.solarPanel;
      }

      // Create product model
      final product = ProductModel(
        id: _isEditingProduct ? _selectedProductId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        category: category,
        brand: _brandController.text,
        capacity: _capacityController.text,
        price: double.parse(_priceController.text),
        installationType: _selectedInstallationType,
        technicalSpecifications: _technicalSpecificationsController.text.isEmpty ? null : _technicalSpecificationsController.text,
        imageUrls: imageUrls,
        stockQuantity: int.parse(_stockQuantityController.text),
        createdAt: _isEditingProduct ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Save or update product
      bool success;
      if (_isEditingProduct) {
        success = await productProvider.updateProduct(product);
      } else {
        success = await productProvider.addProduct(product);
      }

      if (success) {
        _resetProductForm();
        showCustomSnackBar(
          context: context,
          message: 'Product ${_isEditingProduct ? 'updated' : 'added'} successfully',
          isError: false,
        );
      } else {
        final error = productProvider.error ?? 'Unknown error';
        showCustomSnackBar(
          context: context,
          message: 'Failed to ${_isEditingProduct ? 'update' : 'add'} product: $error',
          isError: true,
        );
        productProvider.clearError();
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Error: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isProductLoading = false;
      });
    }
  }

  /// Show dialog to edit an existing product
  void _showEditProductDialog(dynamic product) {
    // Reset form first
    _resetProductForm();

    // Set form values from product
    setState(() {
      _isEditingProduct = true;
      _selectedProductId = product.id;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _brandController.text = product.brand;
      _capacityController.text = product.capacity;
      _priceController.text = product.price.toString();
      _stockQuantityController.text = product.stockQuantity.toString();
      _technicalSpecificationsController.text = product.technicalSpecifications ?? '';
      _selectedInstallationType = product.installationType;
      _existingProductImageUrls = List.from(product.imageUrls);

      // Convert enum category to string
      switch (product.category) {
        case ProductCategory.solarPanel:
          _selectedCategory = 'solarPanel';
          break;
        case ProductCategory.battery:
          _selectedCategory = 'battery';
          break;
        case ProductCategory.inverter:
          _selectedCategory = 'inverter';
          break;
        case ProductCategory.stand:
          _selectedCategory = 'stand';
          break;
        case ProductCategory.accessory:
          _selectedCategory = 'accessory';
          break;
        default:
          _selectedCategory = 'solarPanel';
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Edit Product'),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: SingleChildScrollView(
            child: Form(
              key: _productFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.inventory),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Product Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.category),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: [
                      DropdownMenuItem(value: 'solarPanel', child: Text('Solar Panel')),
                      DropdownMenuItem(value: 'battery', child: Text('Battery')),
                      DropdownMenuItem(value: 'inverter', child: Text('Inverter')),
                      DropdownMenuItem(value: 'stand', child: Text('Stand')),
                      DropdownMenuItem(value: 'accessory', child: Text('Accessory')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Brand
                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.business),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a brand';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Capacity
                  TextFormField(
                    controller: _capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.power),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'e.g., 500W, 1000Wh, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (PKR)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'PKR ',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Please enter a valid number';
                      }
                      if (price <= 0) {
                        return 'Price must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Stock Quantity
                  TextFormField(
                    controller: _stockQuantityController,
                    decoration: InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.inventory_2),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null) {
                        return 'Please enter a valid number';
                      }
                      if (quantity < 0) {
                        return 'Quantity cannot be negative';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Installation Type (optional)
                  TextFormField(
                    initialValue: _selectedInstallationType,
                    decoration: InputDecoration(
                      labelText: 'Installation Type (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.build),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'e.g., Roof-mounted, Ground-mounted, etc.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstallationType = value.isEmpty ? null : value;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Technical Specifications
                  TextFormField(
                    controller: _technicalSpecificationsController,
                    decoration: InputDecoration(
                      labelText: 'Technical Specifications',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.settings),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),

                  // Product Images
                  Text(
                    'Product Images',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Existing images
                  if (_existingProductImageUrls.isNotEmpty) ...[
                    Text(
                      'Existing Images:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _existingProductImageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _existingProductImageUrls[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: Icon(Icons.broken_image, color: Colors.red),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _existingProductImageUrls.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: _pickProductImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Add Images'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Display selected images
                  if (_selectedProductImages.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'New Images:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedProductImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedProductImages[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_productFormKey.currentState!.validate()) {
                _saveProduct();
                Navigator.pop(context);
              }
            },
            child: Text('Update Product'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(dynamic product) {
    // Implement delete product dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Product'),
            content: Text('Are you sure you want to delete ${product.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final productProvider = Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  );
                  await productProvider.deleteProduct(product.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  /// Show dialog with product details
  void _showProductDetailsDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(product.mainImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildProductDetailItem('Name', product.name),
              _buildProductDetailItem('Category', product.categoryName),
              _buildProductDetailItem('Brand', product.brand),
              _buildProductDetailItem('Capacity', product.capacity),
              _buildProductDetailItem('Price', product.formattedPrice),
              _buildProductDetailItem(
                'Stock',
                product.stockQuantity.toString(),
              ),
              _buildProductDetailItem('Description', product.description),
              if (product.technicalSpecifications != null)
                _buildProductDetailItem(
                  'Technical Specifications',
                  product.technicalSpecifications!,
                ),
              if (product.installationType != null)
                _buildProductDetailItem(
                  'Installation Type',
                  product.installationType!,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a product detail item with label and value
  Widget _buildProductDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildServiceManagementTab() {
    final serviceProvider = Provider.of<ServiceProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Services are essential for solar system installation, maintenance, and repair. '
            'You can manage all services from this screen.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          Expanded(
            child: serviceProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildServiceCard(
                        'Installation',
                        'Solar system installation services',
                        Icons.build,
                        Colors.blue,
                      ),
                      _buildServiceCard(
                        'Maintenance',
                        'Regular maintenance services',
                        Icons.handyman,
                        Colors.green,
                      ),
                      _buildServiceCard(
                        'Repair',
                        'Repair services for damaged systems',
                        Icons.home_repair_service,
                        Colors.orange,
                      ),
                      _buildServiceCard(
                        'Consultation',
                        'Expert consultation services',
                        Icons.support_agent,
                        Colors.purple,
                      ),
                      _buildServiceCard(
                        'Cleaning',
                        'Panel cleaning services',
                        Icons.cleaning_services,
                        Colors.teal,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderManagementTab() {
    // Placeholder for order management tab
    return Center(child: Text('Order Management Tab - Coming Soon'));
  }

  Widget _buildKnowledgeBaseTab() {
    // Placeholder for knowledge base tab
    return Center(child: Text('Knowledge Base Tab - Coming Soon'));
  }

  Widget _buildSettingsTab() {
    // Placeholder for settings tab
    return Center(child: Text('Settings Tab - Coming Soon'));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  // Service management methods

  IconData _getIconForServiceType(String type) {
    switch (type.toLowerCase()) {
      case 'installation':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      case 'repair':
        return Icons.home_repair_service;
      case 'consultation':
        return Icons.support_agent;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.miscellaneous_services;
    }
  }

  void _showAddServiceDialog() {
    // Show dialog to add a new service
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Service'),
        content: Text('This functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(dynamic service) {
    // Show dialog to edit a service
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Service'),
        content: Text('This functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteServiceDialog(String serviceId) {
    // Show dialog to confirm service deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Service'),
        content: Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete the service
              Provider.of<ServiceProvider>(context, listen: false).deleteService(serviceId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showServiceDetailsDialog(dynamic service) {
    // Show dialog with service details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Service Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForServiceType(service.serviceType),
                size: 48,
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              _buildProductDetailItem('Type', service.serviceType),
              _buildProductDetailItem('Description', service.description),
              _buildProductDetailItem('Price', service.formattedPrice),
              _buildProductDetailItem('Duration', service.formattedDuration),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
