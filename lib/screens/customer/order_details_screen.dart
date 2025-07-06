import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider_new.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';

/// OrderDetailsScreen displays detailed information about a specific order
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    // Load order details after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
    });
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderId = ModalRoute.of(context)!.settings.arguments as String;
      final orderProvider = Provider.of<CartOrderProvider>(context, listen: false);

      final order = await orderProvider.getOrderById(orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderProvider = Provider.of<CartOrderProvider>(context, listen: false);
      final success = await orderProvider.cancelOrder(_order!.id);

      if (success) {
        // Reload order details to show updated status
        await _loadOrderDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = orderProvider.error ?? 'Failed to cancel order';
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
        title: Text('Order Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _order == null
              ? Center(
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
                        'Order not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'The requested order could not be found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          AppRoutes.navigateAndReplace(context, AppRoutes.orderHistory);
                        },
                        child: Text('Back to Order History'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID and date
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${_order!.id.substring(0, 8)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_order!.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _order!.statusName,
                                      style: TextStyle(
                                        color: _getStatusColor(_order!.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Date: ${DateFormat('MMM d, yyyy').format(_order!.orderDate)}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Payment Method: ${_order!.paymentMethodName}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),

                              // Cancel button (only for pending or processing orders)
                              if (_order!.canBeCancelled) ...[
                                SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.cancel),
                                    label: Text('Cancel Order'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(color: Colors.red),
                                    ),
                                    onPressed: _cancelOrder,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Shipping information
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shipping Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _order!.shippingAddress,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (_order!.city != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  'City: ${_order!.city}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Order items
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Products section
                              if (_order!.items.any((item) => item.isProduct)) ...[
                                Text(
                                  'Products',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ..._order!.items
                                    .where((item) => item.isProduct)
                                    .map((item) => _buildOrderItemRow(item)),
                                SizedBox(height: 16),
                              ],

                              // Services section
                              if (_order!.items.any((item) => item.isService)) ...[
                                Text(
                                  'Services',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ..._order!.items
                                    .where((item) => item.isService)
                                    .map((item) => _buildOrderItemRow(item)),
                                SizedBox(height: 16),
                              ],

                              Divider(),

                              // Order total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _order!.formattedTotalAmount,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Payment instructions (for bank transfer)
                      if (_order!.paymentMethod == PaymentMethod.bankTransfer) ...[
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Instructions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please transfer the total amount to the following bank account:',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text('Bank: Smart Solar Bank'),
                                Text('Account Number: 1234-5678-9012-3456'),
                                Text('Account Name: Smart Solar Solution'),
                                SizedBox(height: 8),
                                Text(
                                  'Please include your Order ID in the payment reference.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
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

                      // Back to order history button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            AppRoutes.navigateAndReplace(context, AppRoutes.orderHistory);
                          },
                          child: Text('Back to Order History'),
                        ),
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Item image (if available)
          if (item.itemImage != null && item.itemImage!.startsWith('http'))
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(item.itemImage!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: Icon(
                item.isProduct ? Icons.inventory_2 : Icons.miscellaneous_services,
                color: Colors.grey[600],
                size: 20,
              ),
            ),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? 'Unknown Item',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.quantity} x ${item.formattedPrice}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Item total price
          Text(
            item.formattedTotalPrice,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
