import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider_new.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../widgets/app_drawer.dart';

/// OrderHistoryScreen displays the user's order history with details about each order
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Provider.of<CartOrderProvider>(context, listen: false).fetchUserOrders();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadOrders,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<CartOrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.error != null) {
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

                if (orderProvider.userOrders.isEmpty) {
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
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your order history will appear here',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            AppRoutes.navigateTo(context, AppRoutes.productCatalog);
                          },
                          child: Text('Browse Products'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orderProvider.userOrders.length,
                  itemBuilder: (context, index) {
                    final order = orderProvider.userOrders[index];
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
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
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(
            context,
            AppRoutes.orderDetails,
            arguments: order.id,
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Order status
              Container(
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

              SizedBox(height: 12),

              // Order items summary
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

              SizedBox(height: 12),

              // Order total and view details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${order.formattedTotalAmount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text('View Details'),
                    onPressed: () {
                      AppRoutes.navigateTo(
                        context,
                        AppRoutes.orderDetails,
                        arguments: order.id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
