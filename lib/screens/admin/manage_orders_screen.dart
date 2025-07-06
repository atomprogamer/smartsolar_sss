import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider_new.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';

/// ManageOrdersScreen allows admins to view and manage all orders
class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  _ManageOrdersScreenState createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  // Filter options
  OrderStatus? _selectedStatus;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Provider.of<CartOrderProvider>(context, listen: false).fetchAllOrders();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderProvider = Provider.of<CartOrderProvider>(context, listen: false);
      final success = await orderProvider.updateOrderStatus(orderId, newStatus);

      if (success) {
        // Reload orders to show updated status
        await _loadOrders();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = orderProvider.error ?? 'Failed to update order status';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by order ID or customer name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.isNotEmpty ? value.toLowerCase() : null;
                      });
                    },
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All orders
                      _buildOrderList(null),

                      // Pending orders
                      _buildOrderList(OrderStatus.pending),

                      // Processing orders
                      _buildOrderList(OrderStatus.processing),

                      // Shipped orders
                      _buildOrderList(OrderStatus.shipped),

                      // Delivered orders
                      _buildOrderList(OrderStatus.delivered),

                      // Cancelled orders
                      _buildOrderList(OrderStatus.cancelled),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderList(OrderStatus? status) {
    return Consumer<CartOrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.error != null && _errorMessage == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  orderProvider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadOrders,
                  child: Text('Try Again'),
                ),
              ],
            ),
          );
        }

        // Filter orders by status if specified
        List<OrderModel> filteredOrders = status != null
            ? orderProvider.allOrders.where((order) => order.status == status).toList()
            : orderProvider.allOrders;

        // Apply search filter if specified
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          filteredOrders = filteredOrders.where((order) {
            // Search by order ID
            if (order.id.toLowerCase().contains(_searchQuery!)) {
              return true;
            }

            // Search by shipping address
            if (order.shippingAddress.toLowerCase().contains(_searchQuery!)) {
              return true;
            }

            // Search by city
            if (order.city != null && order.city!.toLowerCase().contains(_searchQuery!)) {
              return true;
            }

            return false;
          }).toList();
        }

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  status != null
                      ? 'No ${status.toString().split('.').last} orders found'
                      : _searchQuery != null
                          ? 'No orders match your search criteria'
                          : 'No orders have been placed yet',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(context, order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    // Format the order date
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(order.orderDate);

    // Count products and services
    final productItems = order.items.where((item) => item.isProduct).toList();
    final serviceItems = order.items.where((item) => item.isService).toList();

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Order #${order.id.substring(0, 8)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$formattedDate - ${order.formattedTotalAmount}',
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            order.statusName,
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipping information
                Text(
                  'Shipping Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  order.shippingAddress,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                if (order.city != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'City: ${order.city}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                // Order items summary
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),

                if (productItems.isNotEmpty) ...[
                  Text(
                    'Products: ${productItems.length} item${productItems.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],

                if (serviceItems.isNotEmpty) ...[
                  Text(
                    'Services: ${serviceItems.length} item${serviceItems.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                // Update status section
                Text(
                  'Update Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),

                // Status update buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.status != OrderStatus.pending)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.pending,
                        'Pending',
                      ),

                    if (order.status != OrderStatus.processing)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.processing,
                        'Processing',
                      ),

                    if (order.status != OrderStatus.shipped)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.shipped,
                        'Shipped',
                      ),

                    if (order.status != OrderStatus.delivered)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.delivered,
                        'Delivered',
                      ),

                    if (order.status != OrderStatus.completed)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.completed,
                        'Completed',
                      ),

                    if (order.status != OrderStatus.cancelled)
                      _buildStatusButton(
                        context,
                        order,
                        OrderStatus.cancelled,
                        'Cancelled',
                        isDestructive: true,
                      ),
                  ],
                ),

                SizedBox(height: 16),

                // View details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to order details screen
                      AppRoutes.navigateTo(
                        context,
                        AppRoutes.orderDetails,
                        arguments: order.id,
                      );
                    },
                    child: Text('View Full Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    OrderModel order,
    OrderStatus status,
    String label, {
    bool isDestructive = false,
  }) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Update Order Status'),
            content: Text('Are you sure you want to change the status of Order #${order.id.substring(0, 8)} to $label?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Update'),
                onPressed: () {
                  Navigator.pop(context);
                  _updateOrderStatus(order.id, status);
                },
              ),
            ],
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive ? Colors.red : _getStatusColor(status),
        side: BorderSide(
          color: isDestructive ? Colors.red : _getStatusColor(status),
        ),
      ),
      child: Text(label),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
