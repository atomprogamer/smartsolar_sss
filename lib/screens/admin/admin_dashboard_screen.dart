import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/knowledge_provider.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await Future.wait<void>([
      userProvider.fetchPendingUsers(),
      productProvider.fetchProducts(),
      serviceProvider.fetchServices(),
      orderProvider.fetchAllOrders(),
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
    final orderProvider = Provider.of<OrderProvider>(context);

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
                orderProvider,
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
              _buildRecentOrdersList(orderProvider.recentOrders),

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
    OrderProvider orderProvider,
  ) {
    final stats = [
      {
        'title': 'Total Users',
        'value': userProvider.users.length.toString(),
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
        'value': orderProvider.allOrders.length.toString(),
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
      },
      {
        'title': 'Pending Approvals',
        'value': userProvider.pendingUsers.length.toString(),
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

  void _showAddProductDialog() {
    // Implement add product dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Product'),
            content: Text(
              'Add product functionality will be implemented here.',
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

  void _showEditProductDialog(dynamic product) {
    // Implement edit product dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Product'),
            content: Text(
              'Edit product functionality will be implemented here.',
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

  void _showProductDetailsDialog(dynamic product) {
    // Implement product details dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Product Details'),
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
    // Placeholder for service management tab
    return Center(child: Text('Service Management Tab - Coming Soon'));
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
}
