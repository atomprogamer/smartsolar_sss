import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/service_provider.dart';
import '../../models/service_model.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';

/// ServiceCatalogScreen displays a list of services with filtering options
/// Allows users to browse, search, and select services for booking
class ServiceCatalogScreen extends StatefulWidget {
  const ServiceCatalogScreen({super.key});

  @override
  _ServiceCatalogScreenState createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  String _selectedServiceType = 'all';
  String _searchQuery = '';
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.fetchServices();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _selectServiceType(String serviceType) {
    setState(() {
      _selectedServiceType = serviceType;
    });
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<ServiceModel> _getFilteredServices() {
    final serviceProvider = Provider.of<ServiceProvider>(context);

    // Start with all services or filtered by type
    List<ServiceModel> filteredServices;
    switch (_selectedServiceType) {
      case 'installation':
        filteredServices = serviceProvider.installationServices;
        break;
      case 'maintenance':
        filteredServices = serviceProvider.maintenanceServices;
        break;
      case 'repair':
        filteredServices = serviceProvider.repairServices;
        break;
      case 'consultation':
        filteredServices = serviceProvider.consultationServices;
        break;
      case 'cleaning':
        filteredServices = serviceProvider.cleaningServices;
        break;
      default:
        filteredServices = serviceProvider.services;
    }

    // Apply search filter if search query exists
    if (_searchQuery.isNotEmpty) {
      filteredServices = filteredServices.where((service) => 
          service.serviceType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filteredServices;
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final filteredServices = _getFilteredServices();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar 
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _applySearch,
                autofocus: true,
              )
            : Text('Service Catalog'),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Service type tabs
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildServiceTypeTab('all', 'All Services', Icons.home_repair_service),
                _buildServiceTypeTab('installation', 'Installation', Icons.build),
                _buildServiceTypeTab('maintenance', 'Maintenance', Icons.handyman),
                _buildServiceTypeTab('repair', 'Repair', Icons.construction),
                _buildServiceTypeTab('consultation', 'Consultation', Icons.support_agent),
                _buildServiceTypeTab('cleaning', 'Cleaning', Icons.cleaning_services),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredServices.length} Services',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Service grid
          Expanded(
            child: serviceProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No services found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search query',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initializeServices,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: size.width > 600 ? 3 : 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              return _buildServiceCard(context, service);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeTab(String serviceType, String label, IconData icon) {
    final isSelected = _selectedServiceType == serviceType;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _selectServiceType(serviceType),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.secondaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceModel service) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.serviceDetails,
            arguments: service.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: CachedNetworkImage(
                  imageUrl: service.mainImageUrl,
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
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12),
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
                      service.serviceType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        service.formattedDuration,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Price
                  Text(
                    service.formattedPrice,
                    style: TextStyle(
                      color: AppTheme.currencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Book now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.serviceDetails,
                          arguments: service.id,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
