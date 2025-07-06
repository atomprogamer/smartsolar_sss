import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../utils/theme.dart';

/// ManageServicesScreen allows admins to manage services
/// including adding, editing, and deleting services
class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  _ManageServicesScreenState createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _selectedServiceId;

  // Form fields
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _serviceTypeController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _durationController.clear();
    setState(() {
      _selectedImages = [];
      _existingImageUrls = [];
      _isEditing = false;
      _selectedServiceId = null;
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
        final ref = storage.ref().child('services/$fileName');

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

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _uploadImages();

      final service = ServiceModel(
        id: _isEditing ? _selectedServiceId! : DateTime.now().millisecondsSinceEpoch.toString(),
        serviceType: _serviceTypeController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        duration: _durationController.text,
        imageUrls: imageUrls,
        createdAt: _isEditing ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      bool success;
      if (_isEditing) {
        success = await serviceProvider.updateService(service);
      } else {
        success = await serviceProvider.addService(service);
      }

      if (success) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service ${_isEditing ? 'updated' : 'added'} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isEditing ? 'update' : 'add'} service')),
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

  void _editService(ServiceModel service) {
    setState(() {
      _isEditing = true;
      _selectedServiceId = service.id;
      _serviceTypeController.text = service.serviceType;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _durationController.text = service.duration;
      _existingImageUrls = List.from(service.imageUrls);
      _selectedImages = [];
    });
  }

  Future<void> _deleteService(String serviceId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final success = await serviceProvider.deleteService(serviceId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete service')),
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
        title: Text('Manage Services'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ServiceProvider>(context, listen: false).fetchServices();
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
                  // Service list
                  Expanded(
                    flex: 1,
                    child: _buildServiceList(),
                  ),

                  SizedBox(width: 16),

                  // Service form
                  Expanded(
                    flex: 2,
                    child: _buildServiceForm(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceList() {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        if (serviceProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (serviceProvider.services.isEmpty) {
          return Center(child: Text('No services found'));
        }

        return ListView.builder(
          itemCount: serviceProvider.services.length,
          itemBuilder: (context, index) {
            final service = serviceProvider.services[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: service.imageUrls.isNotEmpty
                    ? Image.network(
                        service.imageUrls[0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported);
                        },
                      )
                    : Icon(Icons.image_not_supported),
                title: Text(service.serviceType),
                subtitle: Text('${service.formattedPrice} - ${service.duration}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                      onPressed: () => _editService(service),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Service'),
                            content: Text('Are you sure you want to delete ${service.serviceType}?'),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: Text('Delete'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteService(service.id);
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

  Widget _buildServiceForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _isEditing ? 'Edit Service' : 'Add New Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Service Type
              TextFormField(
                controller: _serviceTypeController,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Installation, Maintenance, Repair, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a service type';
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

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2 hours, 1 day, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Images
              Text(
                'Service Images',
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
                      onPressed: _saveService,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Update Service' : 'Add Service',
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
