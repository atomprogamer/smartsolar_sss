import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';

/// TechnicianDashboardScreen is the main screen for technicians after login
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  _TechnicianDashboardScreenState createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  int _currentIndex = 0;
  final List<String> _tabs = [
    'Dashboard',
    'Service Requests',
    'Maintenance',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      serviceProvider.fetchBookingsByTechnician(authProvider.user?.uid ?? ''),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex]),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman),
            label: 'Maintenance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildServiceRequestsTab();
      case 2:
        return _buildMaintenanceTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final technicianBookings = serviceProvider.technicianBookings;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(user),

              SizedBox(height: 24),

              // Stats cards
              _buildStatsGrid(serviceProvider),

              SizedBox(height: 24),

              // Today's schedule
              Text(
                'Today\'s Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildTodayScheduleList(
                technicianBookings
                    .where(
                      (booking) =>
                          booking.scheduledDate.year == DateTime.now().year &&
                          booking.scheduledDate.month == DateTime.now().month &&
                          booking.scheduledDate.day == DateTime.now().day,
                    )
                    .toList(),
              ),

              SizedBox(height: 24),

              // Upcoming tasks
              Text(
                'Upcoming Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildUpcomingTasksList(
                technicianBookings
                    .where(
                      (booking) =>
                          booking.scheduledDate.isAfter(DateTime.now()) &&
                          booking.status.toLowerCase() == 'confirmed',
                    )
                    .toList(),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserModel? user) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.orange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'T',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Technician'}!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Solar System Technician',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Provide excellent installation and maintenance services to our customers.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ServiceProvider serviceProvider) {
    final stats = [
      {
        'title': 'Total Tasks',
        'value': serviceProvider.technicianBookings.length.toString(),
        'icon': Icons.assignment,
        'color': Colors.orange,
      },
      {
        'title': 'Pending',
        'value':
            serviceProvider.technicianBookings
                .where((b) => b.status.toLowerCase() == 'assigned')
                .length
                .toString(),
        'icon': Icons.pending_actions,
        'color': Colors.blue,
      },
      {
        'title': 'Today',
        'value':
            serviceProvider.technicianBookings
                .where(
                  (b) =>
                      b.scheduledDate.year == DateTime.now().year &&
                      b.scheduledDate.month == DateTime.now().month &&
                      b.scheduledDate.day == DateTime.now().day,
                )
                .length
                .toString(),
        'icon': Icons.today,
        'color': Colors.green,
      },
      {
        'title': 'Completed',
        'value':
            serviceProvider.technicianBookings
                .where((b) => b.status.toLowerCase() == 'completed')
                .length
                .toString(),
        'icon': Icons.check_circle,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 24,
                ),
              ),
              SizedBox(height: 8),
              Text(
                stat['title'] as String,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayScheduleList(List<ServiceBookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No tasks scheduled for today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enjoy your day!',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Icon(Icons.handyman, color: Colors.orange),
            ),
            title: Text(booking.serviceType ?? 'Service Request'),
            subtitle: Text(
              '${booking.formattedScheduledTime} • ${booking.location}',
            ),
            trailing: _getStatusBadge(booking.status),
            onTap: () {
              // View booking details
              _showBookingDetailsDialog(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildUpcomingTasksList(List<ServiceBookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No upcoming tasks'),
        ),
      );
    }

    // Sort by scheduled date
    bookings.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: bookings.length > 5 ? 5 : bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(Icons.event, color: Colors.blue),
            ),
            title: Text(booking.serviceType ?? 'Service Request'),
            subtitle: Text(
              '${booking.formattedScheduledDate} • ${booking.formattedScheduledTime}',
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // View booking details
              _showBookingDetailsDialog(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceRequestsTab() {
    final serviceProvider = Provider.of<ServiceProvider>(context);

    if (serviceProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildServiceRequestsList(
                  serviceProvider.technicianBookings
                      .where((b) => b.status.toLowerCase() == 'assigned')
                      .toList(),
                ),
                _buildServiceRequestsList(
                  serviceProvider.technicianBookings
                      .where((b) => b.status.toLowerCase() == 'in_progress')
                      .toList(),
                ),
                _buildServiceRequestsList(
                  serviceProvider.technicianBookings
                      .where((b) => b.status.toLowerCase() == 'completed')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequestsList(List<ServiceBookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(child: Text('No service requests found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(booking.serviceType ?? 'Service Request'),
                subtitle: Text(
                  '${booking.formattedScheduledDate} • ${booking.formattedScheduledTime}',
                ),
                trailing: _getStatusBadge(booking.status),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (booking.notes != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  if (booking.status.toLowerCase() == 'assigned')
                    TextButton(
                      onPressed: () {
                        // Start service
                        _updateBookingStatus(booking, 'in_progress');
                      },
                      child: Text('Start Service'),
                    ),
                  if (booking.status.toLowerCase() == 'in_progress')
                    TextButton(
                      onPressed: () {
                        // Complete service
                        _showCompleteServiceDialog(booking);
                      },
                      child: Text('Complete'),
                    ),
                  TextButton(
                    onPressed: () {
                      // View details
                      _showBookingDetailsDialog(booking);
                    },
                    child: Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateBookingStatus(ServiceBookingModel booking, String status) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update Status'),
            content: Text(
              'Are you sure you want to ${status == 'in_progress' ? 'start' : 'complete'} this service?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final serviceProvider = Provider.of<ServiceProvider>(
                    context,
                    listen: false,
                  );
                  await serviceProvider.updateBookingStatus(booking.id, status);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service status updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showCompleteServiceDialog(ServiceBookingModel booking) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Complete Service'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add completion notes:'),
                SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the work completed...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final serviceProvider = Provider.of<ServiceProvider>(
                    context,
                    listen: false,
                  );
                  await serviceProvider.updateBookingStatus(
                    booking.id,
                    'completed',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service marked as completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Complete'),
              ),
            ],
          ),
    );
  }

  void _showBookingDetailsDialog(ServiceBookingModel booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Service Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailItem(
                    'Service Type',
                    booking.serviceType ?? 'Service Request',
                  ),
                  _buildDetailItem('Date', booking.formattedScheduledDate),
                  _buildDetailItem('Time', booking.formattedScheduledTime),
                  _buildDetailItem('Location', booking.location),
                  _buildDetailItem('Status', booking.status),
                  if (booking.notes != null)
                    _buildDetailItem('Notes', booking.notes!),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              if (booking.status.toLowerCase() == 'assigned')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateBookingStatus(booking, 'in_progress');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text('Start Service'),
                ),
              if (booking.status.toLowerCase() == 'in_progress')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompleteServiceDialog(booking);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Complete'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    final serviceProvider = Provider.of<ServiceProvider>(context);

    if (serviceProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Filter maintenance bookings
    final maintenanceBookings =
        serviceProvider.technicianBookings
            .where(
              (b) =>
                  b.serviceType?.toLowerCase() == 'maintenance' ||
                  b.serviceType?.toLowerCase() == 'cleaning',
            )
            .toList();

    if (maintenanceBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No maintenance tasks assigned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Maintenance tasks will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: maintenanceBookings.length,
      itemBuilder: (context, index) {
        final booking = maintenanceBookings[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      booking.serviceType?.toLowerCase() == 'cleaning'
                          ? Icons.cleaning_services
                          : Icons.handyman,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.serviceType ?? 'Maintenance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _getStatusBadge(booking.status),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          booking.formattedScheduledDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          booking.formattedScheduledTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (booking.notes != null) ...[
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (booking.status.toLowerCase() == 'assigned')
                          TextButton(
                            onPressed: () {
                              // Start service
                              _updateBookingStatus(booking, 'in_progress');
                            },
                            child: Text('Start'),
                          ),
                        if (booking.status.toLowerCase() == 'in_progress')
                          TextButton(
                            onPressed: () {
                              // Complete service
                              _showCompleteServiceDialog(booking);
                            },
                            child: Text('Complete'),
                          ),
                        TextButton(
                          onPressed: () {
                            // View details
                            _showBookingDetailsDialog(booking);
                          },
                          child: Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
      case 'assigned':
        color = Colors.orange;
        break;
      case 'confirmed':
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.1),
                      image:
                          user?.profilePicture != null
                              ? DecorationImage(
                                image: NetworkImage(user!.profilePicture!),
                                fit: BoxFit.cover,
                              )
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child:
                        user?.profilePicture == null
                            ? Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'T',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                            : null,
                  ),

                  SizedBox(height: 16),

                  // User name
                  Text(
                    user?.name ?? 'Technician',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 4),

                  // User email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),

                  SizedBox(height: 8),

                  // User type badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Solar System Technician',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Edit profile button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to edit profile
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Skills section
            Text(
              'Skills & Expertise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            // Skills card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specialization',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    user?.specialization ??
                        'Solar System Installation & Maintenance',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Experience',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3+ years in solar system installation',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Skills',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'Solar Panel Installation',
                          'Inverter Setup',
                          'Battery Installation',
                          'System Maintenance',
                          'Troubleshooting',
                          'Electrical Wiring',
                        ].map((skill) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Work stats section
            Text(
              'Work Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            // Work stats card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Completed',
                        '42',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'In Progress',
                        '3',
                        Icons.pending_actions,
                        Colors.blue,
                      ),
                      _buildStatItem('Rating', '4.8', Icons.star, Colors.amber),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Performance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        'Excellent',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Account section
            Text(
              'Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            // Account menu items
            _buildProfileMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                // Navigate to notifications
              },
            ),

            _buildProfileMenuItem(
              icon: Icons.lock,
              title: 'Security',
              subtitle: 'Change password and security settings',
              onTap: () {
                // Navigate to security settings
              },
            ),

            _buildProfileMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: () {
                // Navigate to help and support
              },
            ),

            SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (mounted) {
                    AppRoutes.navigateAndRemoveUntil(
                      context,
                      AppRoutes.welcome,
                    );
                  }
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
