import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_snackbar.dart';

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

  // Service type options
  final List<String> _serviceTypes = [
    'installation',
    'maintenance',
    'repair',
    'consultation',
    'cleaning',
  ];
  String _selectedServiceType = 'installation';

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
      _selectedServiceType = 'installation';
    });
  }

  /// Pick multiple images from gallery with limit of 5 total images
  Future<void> _pickImages() async {
    try {
      // Check if we've already reached the maximum number of images
      final int currentImageCount = _existingImageUrls.length + _selectedImages.length;
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

      // Limit the number of images that can be picked
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
          _selectedImages.addAll(validFiles.map((e) => File(e.path)).toList());
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

  /// Upload images to Firebase Storage and return URLs
  Future<List<String>> _uploadImages() async {
    // If no new images, return existing URLs
    if (_selectedImages.isEmpty) {
      return _existingImageUrls;
    }

    final List<String> imageUrls = List.from(_existingImageUrls);
    final storage = FirebaseStorage.instance;

    try {
      // Show progress indicator for multiple images
      if (_selectedImages.length > 1) {
        showCustomSnackBar(
          context: context,
          message: 'Uploading ${_selectedImages.length} images...',
          isError: false,
          duration: Duration(seconds: 1),
        );
      }

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        // Create unique filename with timestamp and index
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i';
        final ref = storage.ref().child('services/$fileName');

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

  /// Save or update a service
  Future<void> _saveService() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one image is selected or exists
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'Please add at least one image for the service',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images and get URLs
      final imageUrls = await _uploadImages();

      // Create service model
      final service = ServiceModel(
        id: _isEditing ? _selectedServiceId! : DateTime.now().millisecondsSinceEpoch.toString(),
        serviceType: _selectedServiceType,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        duration: _durationController.text,
        imageUrls: imageUrls,
        createdAt: _isEditing ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      // Save or update service
      bool success;
      if (_isEditing) {
        success = await serviceProvider.updateService(service);
      } else {
        success = await serviceProvider.addService(service);
      }

      if (success) {
        _resetForm();
        showCustomSnackBar(
          context: context,
          message: 'Service ${_isEditing ? 'updated' : 'added'} successfully',
          isError: false,
        );
      } else {
        final error = serviceProvider.error ?? 'Unknown error';
        showCustomSnackBar(
          context: context,
          message: 'Failed to ${_isEditing ? 'update' : 'add'} service: $error',
          isError: true,
        );
        serviceProvider.clearError();
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Error: $e',
        isError: true,
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
      _selectedServiceType = service.serviceType.toLowerCase();
      _serviceTypeController.text = service.serviceType;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _durationController.text = service.duration;
      _existingImageUrls = List.from(service.imageUrls);
      _selectedImages = [];
    });
  }

  /// Delete a service
  Future<void> _deleteService(String serviceId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      // Get service details for better user feedback
      final service = serviceProvider.services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => ServiceModel.empty(),
      );

      final success = await serviceProvider.deleteService(serviceId);

      if (success) {
        // If editing the service that was just deleted, reset the form
        if (_isEditing && _selectedServiceId == serviceId) {
          _resetForm();
        }

        showCustomSnackBar(
          context: context,
          message: 'Service "${service.serviceType}" deleted successfully',
          isError: false,
        );
      } else {
        final error = serviceProvider.error ?? 'Unknown error';
        showCustomSnackBar(
          context: context,
          message: 'Failed to delete service: $error',
          isError: true,
        );
        serviceProvider.clearError();
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Error deleting service: $e',
        isError: true,
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
          // Add new service button
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            tooltip: 'Add New Service',
            onPressed: () {
              _resetForm();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout based on screen width
                  if (constraints.maxWidth < 800) {
                    // Mobile/tablet layout (stacked)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service form
                        _buildServiceForm(),

                        SizedBox(height: 16),

                        // Service list header
                        Text(
                          'Available Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        // Service list (takes remaining height)
                        Expanded(
                          child: _buildServiceList(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop layout (side by side)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service list
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Services',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Expanded(
                                child: _buildServiceList(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // Service form
                        Expanded(
                          flex: 2,
                          child: _buildServiceForm(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }

  /// Build the service list with real-time updates from Firestore
  Widget _buildServiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Handle error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading services',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Refresh services in provider
                    Provider.of<ServiceProvider>(context, listen: false).fetchServices();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Handle empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 48),
                SizedBox(height: 16),
                Text(
                  'No services found',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Reset form to add new service
                    _resetForm();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add New Service'),
                ),
              ],
            ),
          );
        }

        // Update provider with latest data
        final services = snapshot.data!.docs
            .map((doc) => ServiceModel.fromSnapshot(doc))
            .toList();

        // Sort services by type for better organization
        services.sort((a, b) => a.serviceType.compareTo(b.serviceType));

        // Update provider's services list
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
          if (serviceProvider.services.length != services.length) {
            serviceProvider.services.clear();
            serviceProvider.services.addAll(services);
          }
        });

        // Build the list
        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                leading: service.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          service.imageUrls[0],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(service.serviceTypeIconData, size: 30);
                          },
                        ),
                      )
                    : Icon(service.serviceTypeIconData, size: 30),
                title: Text(
                  service.serviceType.substring(0, 1).toUpperCase() + 
                  service.serviceType.substring(1),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${service.formattedPrice} - ${service.duration}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                      tooltip: 'Edit Service',
                      onPressed: () => _editService(service),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppTheme.errorColor),
                      tooltip: 'Delete Service',
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
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
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
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(service.description),
                        SizedBox(height: 16),
                        if (service.imageUrls.length > 1) ...[
                          Text(
                            'Images:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: service.imageUrls.length,
                              itemBuilder: (context, imgIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      service.imageUrls[imgIndex],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build the service form with improved UI/UX
  Widget _buildServiceForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Form header with icon
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    size: 28,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Service' : 'Add New Service',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              Divider(height: 32),

              // Service Type with improved dropdown
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(_getIconForServiceType(_selectedServiceType)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _serviceTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getIconForServiceType(type)),
                        SizedBox(width: 12),
                        Text(
                          type.substring(0, 1).toUpperCase() + type.substring(1),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedServiceType = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a service type';
                  }
                  return null;
                },
                icon: Icon(Icons.arrow_drop_down_circle),
                isExpanded: true,
              ),

              SizedBox(height: 20),

              // Description with character counter
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
                  hintText: 'Describe the service in detail...',
                  counterText: '${_descriptionController.text.length} characters',
                ),
                maxLines: 4,
                maxLength: 500,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return Text(
                    '$currentLength/$maxLength characters',
                    style: TextStyle(
                      color: currentLength > 450 ? Colors.orange : Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
                onChanged: (value) {
                  // Force rebuild to update character counter
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 20) {
                    return 'Description should be at least 20 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Price with currency symbol
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
                  hintText: '0.00',
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

              SizedBox(height: 20),

              // Duration with suggestions
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.timer),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'e.g., 2 hours, 1 day, etc.',
                  helperText: 'Specify how long the service typically takes',
                  suffixIcon: PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down_circle),
                    tooltip: 'Select common duration',
                    onSelected: (String value) {
                      setState(() {
                        _durationController.text = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        '1 hour',
                        '2 hours',
                        '3 hours',
                        'Half day',
                        '1 day',
                        '2 days',
                        '1 week',
                      ].map((String value) {
                        return PopupMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList();
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Images section with better styling
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_existingImageUrls.length + _selectedImages.length}/5 images',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Image upload button
                    ElevatedButton.icon(
                      onPressed: (_existingImageUrls.length + _selectedImages.length) >= 5 
                          ? null 
                          : _pickImages,
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Add Images'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    if (_existingImageUrls.isEmpty && _selectedImages.isEmpty) ...[
                      SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No images selected',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Existing images
                    if (_existingImageUrls.isNotEmpty) ...[
                      SizedBox(height: 16),
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
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Card(
                                  elevation: 2,
                                  margin: EdgeInsets.only(right: 12, bottom: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _existingImageUrls[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 20,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _existingImageUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
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

                    // Selected images
                    if (_selectedImages.isNotEmpty) ...[
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
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Card(
                                  elevation: 2,
                                  margin: EdgeInsets.only(right: 12, bottom: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 20,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
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

              SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveService,
                      icon: Icon(_isEditing ? Icons.save : Icons.add_circle),
                      label: Text(
                        _isEditing ? 'Update Service' : 'Add Service',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  if (_isEditing) ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetForm,
                        icon: Icon(Icons.cancel),
                        label: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

  /// Get icon for service type
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
}
