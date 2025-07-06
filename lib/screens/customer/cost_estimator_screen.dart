import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/cost_estimate_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cost_estimate_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../utils/validators.dart';

/// CostEstimatorScreen allows users to calculate solar system costs
/// based on their energy requirements and location
class CostEstimatorScreen extends StatefulWidget {
  const CostEstimatorScreen({super.key});

  @override
  _CostEstimatorScreenState createState() => _CostEstimatorScreenState();
}

class _CostEstimatorScreenState extends State<CostEstimatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _energyRequirementController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _showResults = false;
  bool _addingToCart = false;

  @override
  void dispose() {
    _energyRequirementController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Validate and calculate cost estimate
  Future<void> _calculateEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to calculate estimates'),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }

    final costEstimateProvider = Provider.of<CostEstimateProvider>(context, listen: false);

    try {
      await costEstimateProvider.calculateCostEstimate(
        energyRequirement: _energyRequirementController.text.trim(),
        location: _locationController.text.trim(),
        city: _cityController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      setState(() {
        _showResults = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating estimate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Add recommended products to cart
  Future<void> _addToCart() async {
    setState(() {
      _addingToCart = true;
    });

    try {
      final costEstimateProvider = Provider.of<CostEstimateProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Get estimated products and add them to cart
      // This would need to be implemented in CostEstimateProvider to work with CartProvider
      // For now, assuming there's a method to get products from estimate
      costEstimateProvider.addEstimateProductsToCart((product, quantity) {
        cartProvider.addProductToCart(product, quantity);
      });

      setState(() {
        _addingToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Products added to cart'),
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reset form and results
  void _resetForm() {
    setState(() {
      _showResults = false;
    });

    _energyRequirementController.clear();
    _locationController.clear();
    _cityController.clear();
    _notesController.clear();

    final costEstimateProvider = Provider.of<CostEstimateProvider>(context, listen: false);
    costEstimateProvider.clearCurrentEstimate();
  }

  /// Validate energy requirement
  String? _validateEnergyRequirement(String? value) {
    if (value == null || value.isEmpty) {
      return 'Energy requirement is required';
    }

    final energyRegex = RegExp(r'^[0-9]+(\.[0-9]+)?$');
    if (!energyRegex.hasMatch(value)) {
      return 'Enter a valid number';
    }

    final energyValue = double.tryParse(value);
    if (energyValue == null || energyValue <= 0) {
      return 'Energy requirement must be greater than 0';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final costEstimateProvider = Provider.of<CostEstimateProvider>(context);
    final currentEstimate = costEstimateProvider.currentEstimate;
    final isLoading = costEstimateProvider.isLoading;
    final error = costEstimateProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: Text('Solar Cost Estimator'),
        actions: [
          if (_showResults)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetForm,
              tooltip: 'New Estimate',
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _showResults && currentEstimate != null
                  ? _buildResultsView(currentEstimate)
                  : _buildEstimateForm(error),
            ),
    );
  }

  /// Build the estimate input form
  Widget _buildEstimateForm(String? error) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Calculate Solar System Cost',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Enter your energy requirements and location to get a detailed cost estimate for your solar system setup.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 24),

          // Error message
          if (error != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Energy requirement field
          TextFormField(
            controller: _energyRequirementController,
            decoration: InputDecoration(
              labelText: 'Energy Requirement (kW)',
              hintText: 'e.g., 5.5',
              prefixIcon: Icon(Icons.bolt),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixText: 'kW',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: _validateEnergyRequirement,
          ),

          SizedBox(height: 16),

          // Location field
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: 'Enter your full address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: Validators.validateAddress,
            maxLines: 2,
          ),

          SizedBox(height: 16),

          // City field
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City',
              hintText: 'Enter your city',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: Validators.validateCity,
          ),

          SizedBox(height: 16),

          // Notes field
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any specific requirements or questions',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 3,
          ),

          SizedBox(height: 24),

          // Calculate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateEstimate,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Calculate Estimate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Information card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Our estimator calculates costs based on your energy requirements. The estimate includes equipment costs, installation costs, and annual maintenance costs.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
                SizedBox(height: 8),
                Text(
                  'We also recommend products based on your requirements that you can add directly to your cart.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the results view
  Widget _buildResultsView(CostEstimateModel estimate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Your Solar System Estimate',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Based on your ${estimate.energyRequirement} energy requirement',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
          ),
        ),

        SizedBox(height: 24),

        // Cost summary card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                // Total cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cost',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      estimate.formattedTotalCost,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.currencyColor,
                      ),
                    ),
                  ],
                ),

                Divider(height: 24),

                // Cost breakdown
                _buildCostItem(
                  'Equipment Cost',
                  estimate.formattedEquipmentCost,
                  Icons.hardware,
                ),

                SizedBox(height: 8),

                _buildCostItem(
                  'Installation Cost',
                  estimate.formattedInstallationCost,
                  Icons.build,
                ),

                SizedBox(height: 8),

                _buildCostItem(
                  'Annual Maintenance Cost',
                  estimate.formattedMaintenanceCost,
                  Icons.handyman,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),

        // Recommended products
        if (estimate.recommendedProducts != null && estimate.recommendedProducts!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Product list
              ...estimate.recommendedProducts!.map((product) => _buildProductItem(product)),

              SizedBox(height: 16),

              // Add to cart button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addingToCart ? null : _addToCart,
                  icon: _addingToCart
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.shopping_cart),
                  label: Text(
                    'Add All Products to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

        SizedBox(height: 24),

        // New estimate button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _resetForm,
            child: Text(
              'Create New Estimate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        SizedBox(height: 24),

        // Information card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Environmental Impact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'By installing a solar system, you\'ll reduce your carbon footprint and contribute to a cleaner environment. This system will help you save on electricity bills in the long run.',
                style: TextStyle(color: Colors.green.shade800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a cost item row
  Widget _buildCostItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.currencyColor,
          ),
        ),
      ],
    );
  }

  /// Build a recommended product item
  Widget _buildProductItem(RecommendedProductModel product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
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
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),

            SizedBox(width: 12),

            // Product details
            Expanded(
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
                      product.productCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 4),

                  // Product name
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 4),

                  // Quantity and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity: ${product.quantity}',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        product.formattedTotalPrice,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.currencyColor,
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
