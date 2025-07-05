import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/service_model.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

/// ServiceDetailsScreen displays detailed information about a selected service
/// Allows users to book the service by selecting date, time, and location
class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  bool _isLoading = false;
  ServiceModel? _service;
  int _currentImageIndex = 0;
  bool _showFullDescription = false;
  bool _showBookingForm = false;
  bool _isBooking = false;
  String? _errorMessage;

  // Booking form controllers and values
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    final serviceId = ModalRoute.of(context)?.settings.arguments as String?;

    if (serviceId == null) {
      setState(() {
        _errorMessage = 'Service ID not provided';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final service = await serviceProvider.getServiceById(serviceId);

      setState(() {
        _service = service;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load service details: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.secondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.secondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      if (_service == null) {
        throw Exception('Service not found');
      }

      // Combine date and time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final success = await serviceProvider.bookService(
        serviceId: _service!.id,
        scheduledDate: scheduledDateTime,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      setState(() {
        _isBooking = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service booked successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to profile screen to view bookings
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.profile, 
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to book service';
        });
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
        _errorMessage = 'Error booking service: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Service Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Service Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadServiceDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Service Details')),
        body: Center(child: Text('Service not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
      ),
      body: Column(
        children: [
          // Main content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 250,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        items: _service!.imageUrls.isEmpty
                            ? [
                                Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ]
                            : _service!.imageUrls.map((url) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
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
                                    );
                                  },
                                );
                              }).toList(),
                      ),

                      // Image indicators
                      if (_service!.imageUrls.length > 1)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _service!.imageUrls.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? AppTheme.secondaryColor
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),

                  // Service info
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service type badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _service!.serviceType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Service name (using description as name)
                        Text(
                          _service!.description.split('.').first,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 16),

                        // Price and duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _service!.formattedPrice,
                              style: TextStyle(
                                color: AppTheme.currencyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppTheme.textSecondaryColor,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _service!.formattedDuration,
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Description
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          _service!.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: _showFullDescription ? null : 3,
                          overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                        ),

                        if (_service!.description.length > 150)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showFullDescription = !_showFullDescription;
                              });
                            },
                            child: Text(
                              _showFullDescription ? 'Show Less' : 'Read More',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        SizedBox(height: 24),

                        // What to expect section
                        Text(
                          'What to Expect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        _buildExpectationItem(
                          icon: Icons.schedule,
                          title: 'Duration',
                          description: 'Service typically takes ${_service!.formattedDuration}',
                        ),

                        _buildExpectationItem(
                          icon: Icons.person,
                          title: 'Professional Service',
                          description: 'Our trained technicians will handle all aspects of the service',
                        ),

                        _buildExpectationItem(
                          icon: Icons.verified,
                          title: 'Quality Guarantee',
                          description: 'We stand behind our work with a satisfaction guarantee',
                        ),

                        SizedBox(height: 24),

                        // Booking form (conditionally shown)
                        if (_showBookingForm)
                          _buildBookingForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with book now button
          if (!_showBookingForm)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please login to book a service'),
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

                    setState(() {
                      _showBookingForm = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpectationItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Service',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
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
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Date picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Service Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Time picker
          InkWell(
            onTap: () => _selectTime(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Service Time',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _selectedTime.format(context),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Location field
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Service Location',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: Validators.validateAddress,
            enabled: !_isBooking,
            maxLines: 2,
          ),

          SizedBox(height: 16),

          // Notes field
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            enabled: !_isBooking,
            maxLines: 3,
          ),

          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isBooking
                      ? null
                      : () {
                          setState(() {
                            _showBookingForm = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _bookService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isBooking
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
