import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/order_provider_new.dart';
import '../../providers/cart_provider.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';

/// CheckoutScreen allows users to enter shipping information, select payment method, and place an order
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.bankTransfer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartOrderProvider = Provider.of<CartOrderProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.cartItems.isEmpty) {
        setState(() {
          _errorMessage = 'Your cart is empty';
          _isLoading = false;
        });
        return;
      }

      final shippingAddress = _addressController.text;
      final city = _cityController.text;

      // Create a GeoPoint for the location (in a real app, this would be from a map or geocoding service)
      // For now, we'll use a dummy location
      final location = GeoPoint(0, 0);

      final orderId = await cartOrderProvider.createOrder(
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
        city: city,
        location: location,
      );

      if (orderId != null) {
        // Order created successfully
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Order Placed Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your order has been placed successfully.'),
                SizedBox(height: 8),
                Text('Order ID: $orderId'),
                SizedBox(height: 16),
                if (_selectedPaymentMethod == PaymentMethod.bankTransfer) ...[
                  Text(
                    'Payment Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Please transfer the total amount to the following bank account:'),
                  SizedBox(height: 8),
                  Text('Bank: Smart Solar Bank'),
                  Text('Account Number: 1234-5678-9012-3456'),
                  Text('Account Name: Smart Solar Solution'),
                  SizedBox(height: 8),
                  Text('Please include your Order ID in the payment reference.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                child: Text('View Order History'),
                onPressed: () {
                  Navigator.pop(context);
                  // Ensure order is fetched before navigating
                  final orderProvider = Provider.of<CartOrderProvider>(context, listen: false);
                  orderProvider.fetchUserOrders().then((_) {
                    AppRoutes.navigateAndReplace(context, AppRoutes.orderHistory);
                  });
                },
              ),
              ElevatedButton(
                child: Text('Continue Shopping'),
                onPressed: () {
                  Navigator.pop(context);
                  AppRoutes.navigateAndReplace(context, AppRoutes.productCatalog);
                },
              ),
            ],
          ),
        );
      } else {
        // Error creating order
        setState(() {
          _errorMessage = cartOrderProvider.error ?? 'Failed to create order';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Consumer2<CartOrderProvider, CartProvider>(
        builder: (context, cartOrderProvider, cartProvider, child) {
          if (cartOrderProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (cartProvider.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add products or services to your cart',
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

          // Filter cart items into products and services
          final productItems = cartProvider.productItems;
          final serviceItems = cartProvider.serviceItems;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Products summary
                          if (productItems.isNotEmpty) ...[
                            Text(
                              'Products (${productItems.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            ...productItems.map((item) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.itemName ?? 'Unknown Product'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(item.formattedTotalPrice),
                                ],
                              ),
                            )),
                            SizedBox(height: 8),
                          ],

                          // Services summary
                          if (serviceItems.isNotEmpty) ...[
                            Text(
                              'Services (${serviceItems.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            ...serviceItems.map((item) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.itemName ?? 'Unknown Service'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(item.formattedTotalPrice),
                                ],
                              ),
                            )),
                            SizedBox(height: 8),
                          ],

                          Divider(),

                          // Total
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
                                cartProvider.formattedCartTotal,
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

                  SizedBox(height: 24),

                  // Shipping information
                  Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Shipping Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your shipping address';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // City
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Order Notes (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: 24),

                  // Payment method
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Bank transfer
                  RadioListTile<PaymentMethod>(
                    title: Text('Bank Transfer'),
                    subtitle: Text('Pay via bank transfer'),
                    value: PaymentMethod.bankTransfer,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),

                  // Cash on delivery
                  RadioListTile<PaymentMethod>(
                    title: Text('Cash on Delivery'),
                    subtitle: Text('Pay when you receive your order'),
                    value: PaymentMethod.cashOnDelivery,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),

                  SizedBox(height: 24),

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

                  // Place order button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
