import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

/// ManageProductsScreen allows admins to manage products
/// including adding, editing, and deleting products
class ManageProductsScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const ManageProductsScreen({super.key, this.productToEdit});

  @override
  _ManageProductsScreenState createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    // Initialize form fields if a product is passed for editing
    if (widget.productToEdit != null) {
      _initializeProductForEditing(widget.productToEdit!);
    }
  }

  void _initializeProductForEditing(ProductModel product) {
    setState(() {
      _isEditing = true;
      _selectedProductId = product.id;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _selectedCategory = product.category;
      _brandController.text = product.brand;
      _capacityController.text = product.capacity;
      _priceController.text = product.price.toString();
      _stockQuantityController.text = product.stockQuantity.toString();
      _technicalSpecificationsController.text = product.technicalSpecifications ?? '';
      _installationTypeController.text = product.installationType ?? '';
      _existingImageUrls = List.from(product.imageUrls);
      _selectedImages = [];
    });
  }

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _capacityController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _technicalSpecificationsController = TextEditingController();
  final _installationTypeController = TextEditingController();

  ProductCategory _selectedCategory = ProductCategory.solarPanel;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _capacityController.dispose();
    _stockQuantityController.dispose();
    _technicalSpecificationsController.dispose();
    _installationTypeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _brandController.clear();
    _capacityController.clear();
    _stockQuantityController.clear();
    _technicalSpecificationsController.clear();
    _installationTypeController.clear();
    setState(() {
      _selectedCategory = ProductCategory.solarPanel;
      _selectedImages = [];
      _existingImageUrls = [];
      _isEditing = false;
      _selectedProductId = null;
    });
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return _existingImageUrls;
    }

    final List<String> imageUrls = List.from(_existingImageUrls);
    final storage = FirebaseStorage.instance;

    try {
      for (final image in _selectedImages) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child('products/$fileName');

        final uploadTask = ref.putFile(image);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
      return imageUrls;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _uploadImages();

      final product = ProductModel(
        id: _isEditing ? _selectedProductId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        brand: _brandController.text,
        capacity: _capacityController.text,
        price: double.parse(_priceController.text),
        installationType: _installationTypeController.text,
        technicalSpecifications: _technicalSpecificationsController.text,
        imageUrls: imageUrls,
        stockQuantity: int.parse(_stockQuantityController.text),
        createdAt: _isEditing ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      bool success;
      if (_isEditing) {
        success = await productProvider.updateProduct(product);
      } else {
        success = await productProvider.addProduct(product);
      }

      if (success) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ${_isEditing ? 'updated' : 'added'} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isEditing ? 'update' : 'add'} product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editProduct(ProductModel product) {
    setState(() {
      _isEditing = true;
      _selectedProductId = product.id;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _selectedCategory = product.category;
      _brandController.text = product.brand;
      _capacityController.text = product.capacity;
      _priceController.text = product.price.toString();
      _stockQuantityController.text = product.stockQuantity.toString();
      _technicalSpecificationsController.text = product.technicalSpecifications ?? '';
      _installationTypeController.text = product.installationType ?? '';
      _existingImageUrls = List.from(product.imageUrls);
      _selectedImages = [];
    });
  }

  Future<void> _deleteProduct(String productId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(productId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false).fetchProducts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product list
                  Expanded(
                    flex: 1,
                    child: _buildProductList(),
                  ),

                  SizedBox(width: 16),

                  // Product form
                  Expanded(
                    flex: 2,
                    child: _buildProductForm(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (productProvider.products.isEmpty) {
          return Center(child: Text('No products found'));
        }

        return ListView.builder(
          itemCount: productProvider.products.length,
          itemBuilder: (context, index) {
            final product = productProvider.products[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls[0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported);
                        },
                      )
                    : Icon(Icons.image_not_supported),
                title: Text(product.name),
                subtitle: Text('${product.categoryName} - ${product.formattedPrice}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                      onPressed: () => _editProduct(product),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Product'),
                            content: Text('Are you sure you want to delete ${product.name}?'),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: Text('Delete'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteProduct(product.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _isEditing ? 'Edit Product' : 'Add New Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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

              // Category
              DropdownButtonFormField<ProductCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ProductCategory.values.map((category) {
                  return DropdownMenuItem<ProductCategory>(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a capacity';
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
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Installation Type
              TextFormField(
                controller: _installationTypeController,
                decoration: InputDecoration(
                  labelText: 'Installation Type (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 16),

              // Technical Specifications
              TextFormField(
                controller: _technicalSpecificationsController,
                decoration: InputDecoration(
                  labelText: 'Technical Specifications (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 16),

              // Images
              Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              // Existing images
              if (_existingImageUrls.isNotEmpty)
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              _existingImageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _existingImageUrls.removeAt(index);
                                });
                              },
                              child: Container(
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

              SizedBox(height: 8),

              // Selected images
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
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

              SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Add Images'),
              ),

              SizedBox(height: 24),

              // Submit button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Update Product' : 'Add Product',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  if (_isEditing) ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
